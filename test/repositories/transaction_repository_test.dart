import 'dart:io';

import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Transaction> box;
  late TransactionRepository repository;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TransactionSourceAdapter());
    // Use a unique box name per test: Hive caches open boxes by name in
    // memory, so reusing a name across tests could return a stale instance.
    box = await Hive.openBox<Transaction>('transactions_test_${boxCounter++}');
    repository = TransactionRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Transaction makeTx(String id, DateTime date, double amount) {
    return Transaction(id: id, date: date, amount: amount, description: 'Test $id', categoryId: 'sonstiges');
  }

  test('save and getAll roundtrip', () async {
    await repository.save(makeTx('a', DateTime(2024, 5, 1), -10));
    await repository.save(makeTx('b', DateTime(2024, 5, 2), 20));
    expect(repository.getAll(), hasLength(2));
  });

  test('getForMonth filters by year and month', () async {
    await repository.save(makeTx('a', DateTime(2024, 5, 15), -10));
    await repository.save(makeTx('b', DateTime(2024, 6, 1), -20));
    await repository.save(makeTx('c', DateTime(2023, 5, 15), -30));

    final may2024 = repository.getForMonth(2024, 5);
    expect(may2024, hasLength(1));
    expect(may2024.first.id, 'a');
  });

  test('getForYear filters by year and sorts ascending by date', () async {
    await repository.save(makeTx('a', DateTime(2024, 12, 1), -10));
    await repository.save(makeTx('b', DateTime(2024, 1, 1), -20));

    final year2024 = repository.getForYear(2024);
    expect(year2024, hasLength(2));
    expect(year2024.first.id, 'b');
    expect(year2024.last.id, 'a');
  });

  test('delete removes transaction', () async {
    await repository.save(makeTx('a', DateTime(2024, 5, 1), -10));
    await repository.delete('a');
    expect(repository.getAll(), isEmpty);
  });

  test('saveAll persists multiple transactions at once', () async {
    await repository.saveAll([
      makeTx('a', DateTime(2024, 5, 1), -10),
      makeTx('b', DateTime(2024, 5, 2), -20),
    ]);
    expect(repository.getAll(), hasLength(2));
  });
}
