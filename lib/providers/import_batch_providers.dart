import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/import_batch.dart';
import 'repository_providers.dart';
import 'salary_slip_providers.dart';
import 'transaction_providers.dart';

class ImportBatchNotifier extends Notifier<List<ImportBatch>> {
  @override
  List<ImportBatch> build() {
    final list = ref.watch(importBatchRepositoryProvider).getAll();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> add(ImportBatch batch) async {
    await ref.read(importBatchRepositoryProvider).save(batch);
    ref.invalidateSelf();
  }

  /// Undoes a whole import: deletes every transaction and salary slip it
  /// added, then the batch record itself - "jumps back" to the state right
  /// before that import ran.
  Future<void> undo(String batchId) async {
    final batches = ref.read(importBatchRepositoryProvider).getAll();
    final batch = batches.where((b) => b.id == batchId).firstOrNull;
    if (batch == null) return;

    final transactionRepo = ref.read(transactionRepositoryProvider);
    for (final id in batch.transactionIds) {
      await transactionRepo.delete(id);
    }
    final salaryRepo = ref.read(salarySlipRepositoryProvider);
    for (final id in batch.salarySlipIds) {
      await salaryRepo.delete(id);
    }
    await ref.read(importBatchRepositoryProvider).delete(batchId);

    ref.invalidate(transactionNotifierProvider);
    ref.invalidate(salarySlipNotifierProvider);
    ref.invalidateSelf();
  }
}

final importBatchNotifierProvider = NotifierProvider<ImportBatchNotifier, List<ImportBatch>>(ImportBatchNotifier.new);
