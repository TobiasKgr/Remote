import 'dart:io';

import 'package:finance_analyzer/models/budget.dart';
import 'package:finance_analyzer/repositories/budget_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Budget> box;
  late BudgetRepository repository;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_analyzer_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(BudgetAdapter());
    box = await Hive.openBox<Budget>('budgets_test_${boxCounter++}');
    repository = BudgetRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('save and getForCategory roundtrip', () async {
    await repository.save(Budget(categoryId: 'lebensmittel', monthlyLimit: 300));
    final budget = repository.getForCategory('lebensmittel');
    expect(budget, isNotNull);
    expect(budget!.monthlyLimit, 300);
  });

  test('save overwrites existing budget for the same category', () async {
    await repository.save(Budget(categoryId: 'lebensmittel', monthlyLimit: 300));
    await repository.save(Budget(categoryId: 'lebensmittel', monthlyLimit: 250));
    expect(repository.getAll(), hasLength(1));
    expect(repository.getForCategory('lebensmittel')!.monthlyLimit, 250);
  });

  test('delete removes the budget', () async {
    await repository.save(Budget(categoryId: 'lebensmittel', monthlyLimit: 300));
    await repository.delete('lebensmittel');
    expect(repository.getForCategory('lebensmittel'), isNull);
  });
}
