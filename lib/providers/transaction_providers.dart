import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import 'person_providers.dart';
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

  /// Deletes the transaction. If it's one half of an internal transfer
  /// (see [Transaction.transferGroupId]), the other half is deleted too, so
  /// a transfer is always removed as a whole rather than leaving an
  /// orphaned single-sided booking.
  Future<void> remove(String id) async {
    final repository = ref.read(transactionRepositoryProvider);
    final transaction = repository.getById(id);
    await repository.delete(id);

    final groupId = transaction?.transferGroupId;
    if (groupId != null) {
      final siblings = repository.getAll().where((t) => t.transferGroupId == groupId && t.id != id);
      for (final sibling in siblings) {
        await repository.delete(sibling.id);
      }
    }
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
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final all = ref.watch(transactionNotifierProvider);
  final byMonth = all.where((t) => t.date.year == month.year && t.date.month == month.month);
  final filtered = filterByPerson(byMonth, personFilter, (t) => t.personId).toList();
  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

final transactionsForSelectedYearProvider = Provider<List<Transaction>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final personFilter = ref.watch(selectedPersonFilterProvider);
  final all = ref.watch(transactionNotifierProvider);
  final byYear = all.where((t) => t.date.year == year);
  final filtered = filterByPerson(byYear, personFilter, (t) => t.personId).toList();
  filtered.sort((a, b) => a.date.compareTo(b.date));
  return filtered;
});
