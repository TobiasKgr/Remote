import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cash_flow_projection_service.dart';
import 'account_providers.dart';
import 'asset_providers.dart';
import 'person_providers.dart';
import 'recurring_payment_providers.dart';
import 'transaction_providers.dart';

/// Projects net worth forward from today using the already-detected
/// recurring payments as the only assumed future events - i.e. "what's
/// already committed", not a full spending forecast. Uses the same static
/// assets/liabilities constant-offset convention as [netWorthHistoryProvider]
/// so the projection is a seamless continuation of that same value.
final cashFlowProjectionProvider = Provider<List<CashFlowProjectionPoint>>((ref) {
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final accounts = filterByPerson(ref.watch(accountNotifierProvider), personFilter, (a) => a.personId).toList();
  final assets = filterByPerson(ref.watch(assetNotifierProvider), personFilter, (a) => a.personId).toList();
  final transactions = ref.watch(transactionNotifierProvider);
  final accountsTotal = computeAccountBalances(accounts, transactions).values.fold<double>(0, (s, v) => s + v);
  final staticAssetsTotal = assets.fold<double>(0, (s, a) => s + (a.isLiability ? -a.value : a.value));
  return computeCashFlowProjection(currentBalance: accountsTotal + staticAssetsTotal, recurringGroups: ref.watch(recurringPaymentsProvider));
});
