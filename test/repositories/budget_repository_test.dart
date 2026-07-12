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

  test('save and getById roundtrip for the default budget', () async {
    await repository.save(Budget(id: Budget.defaultId('lebensmittel'), categoryId: 'lebensmittel', monthlyLimit: 300));
    final budget = repository.getById(Budget.defaultId('lebensmittel'));
    expect(budget, isNotNull);
    expect(budget!.monthlyLimit, 300);
  });

  test('save overwrites existing budget with the same id', () async {
    await repository.save(Budget(id: Budget.defaultId('lebensmittel'), categoryId: 'lebensmittel', monthlyLimit: 300));
    await repository.save(Budget(id: Budget.defaultId('lebensmittel'), categoryId: 'lebensmittel', monthlyLimit: 250));
    expect(repository.getAll(), hasLength(1));
    expect(repository.getById(Budget.defaultId('lebensmittel'))!.monthlyLimit, 250);
  });

  test('default budget and month override for the same category coexist', () async {
    await repository.save(Budget(id: Budget.defaultId('lebensmittel'), categoryId: 'lebensmittel', monthlyLimit: 300));
    await repository.save(Budget(
      id: Budget.overrideId('lebensmittel', 2026, 12),
      categoryId: 'lebensmittel',
      monthlyLimit: 500,
      year: 2026,
      month: 12,
    ));
    expect(repository.getAll(), hasLength(2));
  });

  test('delete removes the budget', () async {
    await repository.save(Budget(id: Budget.defaultId('lebensmittel'), categoryId: 'lebensmittel', monthlyLimit: 300));
    await repository.delete(Budget.defaultId('lebensmittel'));
    expect(repository.getById(Budget.defaultId('lebensmittel')), isNull);
  });
}
