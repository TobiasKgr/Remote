import 'dart:io';

import 'package:finance_analyzer/models/import_batch.dart';
import 'package:finance_analyzer/repositories/import_batch_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<ImportBatch> box;
  late ImportBatchRepository repository;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(ImportBatchAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ImportSourceAdapter());
    box = await Hive.openBox<ImportBatch>('import_batches_test_${boxCounter++}');
    repository = ImportBatchRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  ImportBatch makeBatch(String id, {ImportSource source = ImportSource.kontoauszug}) {
    return ImportBatch(id: id, timestamp: DateTime(2026, 3, 1), source: source, label: 'Test $id', transactionIds: ['t1', 't2']);
  }

  test('save and getAll roundtrip, inklusive Quelle und verknüpfter IDs', () async {
    await repository.save(makeBatch('a', source: ImportSource.gehalt));
    final all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.single.source, ImportSource.gehalt);
    expect(all.single.transactionIds, ['t1', 't2']);
  });

  test('delete removes the batch', () async {
    await repository.save(makeBatch('a'));
    await repository.delete('a');
    expect(repository.getAll(), isEmpty);
  });
}
