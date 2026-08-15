import 'dart:io';

import 'package:finance_analyzer/models/import_batch.dart';
import 'package:finance_analyzer/models/salary_slip.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/import_batch_providers.dart';
import 'package:finance_analyzer/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;
  late Box<Transaction> transactionBox;
  late Box<SalarySlip> salaryBox;
  late Box<ImportBatch> batchBox;
  var boxSuffix = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TransactionSourceAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SalarySlipAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(ImportBatchAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ImportSourceAdapter());

    final suffix = boxSuffix++;
    transactionBox = await Hive.openBox<Transaction>('tx_test_$suffix');
    salaryBox = await Hive.openBox<SalarySlip>('salary_test_$suffix');
    batchBox = await Hive.openBox<ImportBatch>('batch_test_$suffix');

    container = ProviderContainer(overrides: [
      transactionBoxProvider.overrideWithValue(transactionBox),
      salarySlipBoxProvider.overrideWithValue(salaryBox),
      importBatchBoxProvider.overrideWithValue(batchBox),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await transactionBox.deleteFromDisk();
    await salaryBox.deleteFromDisk();
    await batchBox.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Transaction makeTx(String id) => Transaction(id: id, date: DateTime(2026, 3, 1), amount: -10, description: 'Test $id', categoryId: 'sonstiges');

  test('undo löscht alle Buchungen des Imports und den Verlaufseintrag selbst, lässt andere Buchungen unberührt', () async {
    final txRepo = container.read(transactionRepositoryProvider);
    await txRepo.save(makeTx('a'));
    await txRepo.save(makeTx('b'));
    await txRepo.save(makeTx('untouched'));

    await container.read(importBatchNotifierProvider.notifier).add(ImportBatch(
          id: 'batch1',
          timestamp: DateTime(2026, 3, 1),
          source: ImportSource.kontoauszug,
          label: '2 Buchungen importiert',
          transactionIds: ['a', 'b'],
        ));

    expect(container.read(importBatchNotifierProvider), hasLength(1));

    await container.read(importBatchNotifierProvider.notifier).undo('batch1');

    expect(container.read(importBatchNotifierProvider), isEmpty);
    final remainingIds = txRepo.getAll().map((t) => t.id).toSet();
    expect(remainingIds, {'untouched'});
  });

  test('undo mit unbekannter Batch-ID ist ein No-Op statt zu crashen', () async {
    await container.read(importBatchNotifierProvider.notifier).undo('does-not-exist');
    expect(container.read(importBatchNotifierProvider), isEmpty);
  });
}
