import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import 'repository_providers.dart';
import 'transaction_providers.dart';

class AccountNotifier extends Notifier<List<Account>> {
  @override
  List<Account> build() {
    final list = ref.watch(accountRepositoryProvider).getAll();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> upsert(Account account) async {
    await ref.read(accountRepositoryProvider).save(account);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(accountRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final accountNotifierProvider = NotifierProvider<AccountNotifier, List<Account>>(AccountNotifier.new);

/// Pure function (no Riverpod dependency): an account's balance is its
/// starting balance plus every transaction ever booked to it (all time, not
/// filtered by month - transfers are included since they move real money).
double computeAccountBalance(Account account, List<Transaction> allTransactions) {
  final sum = allTransactions.where((t) => t.accountId == account.id).fold<double>(0, (s, t) => s + t.amount);
  return account.startingBalance + sum;
}

Map<String, double> computeAccountBalances(List<Account> accounts, List<Transaction> allTransactions) {
  return {for (final account in accounts) account.id: computeAccountBalance(account, allTransactions)};
}

final accountBalancesProvider = Provider<Map<String, double>>((ref) {
  final accounts = ref.watch(accountNotifierProvider);
  final transactions = ref.watch(transactionNotifierProvider);
  return computeAccountBalances(accounts, transactions);
});
