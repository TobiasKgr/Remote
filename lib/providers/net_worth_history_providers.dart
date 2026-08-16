import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import 'account_providers.dart';
import 'asset_providers.dart';
import 'person_providers.dart';
import 'transaction_providers.dart';

/// One month's net-worth snapshot.
class NetWorthPoint {
  const NetWorthPoint({required this.month, required this.netWorth, required this.hasData});

  /// First-of-month; the value is the balance as of this month's end.
  final DateTime month;
  final double netWorth;

  /// False when no tracked account had a transaction booked *in this
  /// specific month* - the value is still carried forward (a balance
  /// doesn't change without a booking), but nothing confirms it for this
  /// month specifically, e.g. because no statement covering it was ever
  /// imported. Shown as a gap/unconfirmed point rather than hidden, since
  /// the carried-forward value is still the best available estimate.
  final bool hasData;
}

/// Pure function (no Riverpod dependency): reconstructs each tracked
/// account's balance at every month-end from [account.startingBalance] plus
/// its transactions up to that point, sums them across all accounts, and
/// adds the *current* static assets/liabilities total as a constant offset
/// (those have no history of their own - just a manually maintained current
/// value - so this is the closest consistent match to [computeNetWorth],
/// the same definition the rest of the app uses for "Nettovermögen").
///
/// The range covered starts at the month of the earliest transaction across
/// any tracked account and ends at [referenceDate]'s month (default: now).
/// Accounts with no transactions at all don't extend the range.
List<NetWorthPoint> computeNetWorthHistory({
  required List<Account> accounts,
  required List<Transaction> transactions,
  required List<Asset> assets,
  DateTime? referenceDate,
}) {
  if (accounts.isEmpty) return [];

  final accountIds = accounts.map((a) => a.id).toSet();
  final byAccount = <String, List<Transaction>>{};
  for (final t in transactions) {
    if (t.accountId == null || !accountIds.contains(t.accountId)) continue;
    byAccount.putIfAbsent(t.accountId!, () => []).add(t);
  }
  for (final list in byAccount.values) {
    list.sort((a, b) => a.date.compareTo(b.date));
  }
  if (byAccount.isEmpty) return [];

  final allDates = byAccount.values.expand((l) => l).map((t) => t.date).toList()..sort();
  final monthsWithData = allDates.map((d) => DateTime(d.year, d.month)).toSet();

  final reference = referenceDate ?? DateTime.now();
  final start = DateTime(allDates.first.year, allDates.first.month);
  final end = DateTime(reference.year, reference.month);

  final staticAssetsTotal = assets.fold<double>(0, (s, a) => s + (a.isLiability ? -a.value : a.value));

  final cursorIndex = {for (final a in accounts) a.id: 0};
  final runningSum = {for (final a in accounts) a.id: a.startingBalance};

  final points = <NetWorthPoint>[];
  var month = start;
  while (!month.isAfter(end)) {
    final nextMonth = DateTime(month.year, month.month + 1);

    for (final account in accounts) {
      final list = byAccount[account.id] ?? const [];
      var idx = cursorIndex[account.id]!;
      var sum = runningSum[account.id]!;
      while (idx < list.length && list[idx].date.isBefore(nextMonth)) {
        sum += list[idx].amount;
        idx++;
      }
      cursorIndex[account.id] = idx;
      runningSum[account.id] = sum;
    }

    final accountsTotal = runningSum.values.fold<double>(0, (s, v) => s + v);
    points.add(NetWorthPoint(month: month, netWorth: accountsTotal + staticAssetsTotal, hasData: monthsWithData.contains(month)));
    month = nextMonth;
  }

  return points;
}

final netWorthHistoryProvider = Provider<List<NetWorthPoint>>((ref) {
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final accounts = filterByPerson(ref.watch(accountNotifierProvider), personFilter, (a) => a.personId).toList();
  final assets = filterByPerson(ref.watch(assetNotifierProvider), personFilter, (a) => a.personId).toList();
  final transactions = ref.watch(transactionNotifierProvider);
  return computeNetWorthHistory(accounts: accounts, transactions: transactions, assets: assets);
});
