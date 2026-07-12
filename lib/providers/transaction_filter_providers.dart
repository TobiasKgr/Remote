import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import 'transaction_providers.dart';

class AmountRange {
  const AmountRange({this.min, this.max});

  final double? min;
  final double? max;

  bool get isActive => min != null || max != null;
}

final transactionSearchQueryProvider = StateProvider<String>((ref) => '');
final transactionCategoryFilterProvider = StateProvider<String?>((ref) => null);
final transactionAmountRangeProvider = StateProvider<AmountRange>((ref) => const AmountRange());

/// Pure function (no Riverpod dependency) so it can be unit-tested directly.
/// [query] matches case-insensitively against the description. Amounts are
/// compared by absolute value, since users think in terms of "between 10
/// and 50 €" regardless of income/expense sign.
List<Transaction> filterTransactions(
  List<Transaction> transactions, {
  String query = '',
  String? categoryId,
  double? minAmount,
  double? maxAmount,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return transactions.where((t) {
    if (normalizedQuery.isNotEmpty && !t.description.toLowerCase().contains(normalizedQuery)) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    final absAmount = t.amount.abs();
    if (minAmount != null && absAmount < minAmount) return false;
    if (maxAmount != null && absAmount > maxAmount) return false;
    return true;
  }).toList();
}

/// [transactionsForSelectedMonthProvider] filtered further by the search
/// query, category and amount range - used only by the Buchungen screen so
/// aggregate providers (Dashboard, Budgets, ...) stay unaffected.
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final base = ref.watch(transactionsForSelectedMonthProvider);
  final query = ref.watch(transactionSearchQueryProvider);
  final categoryId = ref.watch(transactionCategoryFilterProvider);
  final amountRange = ref.watch(transactionAmountRangeProvider);
  return filterTransactions(base, query: query, categoryId: categoryId, minAmount: amountRange.min, maxAmount: amountRange.max);
});
