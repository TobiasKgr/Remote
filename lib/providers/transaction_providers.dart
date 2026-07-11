import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import 'repository_providers.dart';

class TransactionNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    return ref.watch(transactionRepositoryProvider).getAll();
  }

  Future<void> upsert(Transaction transaction) async {
    await ref.read(transactionRepositoryProvider).save(transaction);
    ref.invalidateSelf();
  }

  Future<void> upsertAll(Iterable<Transaction> transactions) async {
    await ref.read(transactionRepositoryProvider).saveAll(transactions);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(transactionRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final transactionNotifierProvider = NotifierProvider<TransactionNotifier, List<Transaction>>(TransactionNotifier.new);

/// Currently selected month shown on the Dashboard/Transactions screens.
/// Stored as the first day of the month.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Currently selected year shown on the Yearly overview screen.
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final transactionsForSelectedMonthProvider = Provider<List<Transaction>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final all = ref.watch(transactionNotifierProvider);
  final filtered = all.where((t) => t.date.year == month.year && t.date.month == month.month).toList();
  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

final transactionsForSelectedYearProvider = Provider<List<Transaction>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final all = ref.watch(transactionNotifierProvider);
  final filtered = all.where((t) => t.date.year == year).toList();
  filtered.sort((a, b) => a.date.compareTo(b.date));
  return filtered;
});
