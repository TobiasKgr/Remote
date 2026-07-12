import 'package:finance_analyzer/models/budget.dart';
import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/budget_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = [
    Category(id: 'lebensmittel', name: 'Lebensmittel', type: CategoryType.expense, colorValue: 0xFF000000),
    Category(id: 'freizeit', name: 'Freizeit', type: CategoryType.expense, colorValue: 0xFF000000),
  ];

  Transaction expense(String id, String categoryId, double amount) {
    return Transaction(id: id, date: DateTime(2026, 7, 1), amount: -amount, description: id, categoryId: categoryId);
  }

  test('berechnet Ausgaben je Budget-Kategorie', () {
    final budgets = [Budget(categoryId: 'lebensmittel', monthlyLimit: 300)];
    final transactions = [expense('a', 'lebensmittel', 120), expense('b', 'lebensmittel', 50)];

    final progress = computeBudgetProgress(budgets, categories, transactions);
    expect(progress, hasLength(1));
    expect(progress.first.spent, 170);
    expect(progress.first.limit, 300);
    expect(progress.first.ratio, closeTo(170 / 300, 0.0001));
  });

  test('Kategorien ohne Budget werden nicht aufgeführt', () {
    final budgets = [Budget(categoryId: 'lebensmittel', monthlyLimit: 300)];
    final transactions = [expense('a', 'freizeit', 50)];

    final progress = computeBudgetProgress(budgets, categories, transactions);
    expect(progress, hasLength(1));
    expect(progress.first.spent, 0);
  });

  test('gelöschte Kategorie wird ignoriert', () {
    final budgets = [Budget(categoryId: 'geloescht', monthlyLimit: 100)];
    final progress = computeBudgetProgress(budgets, categories, []);
    expect(progress, isEmpty);
  });

  test('sortiert absteigend nach Auslastung (ratio)', () {
    final budgets = [
      Budget(categoryId: 'lebensmittel', monthlyLimit: 100),
      Budget(categoryId: 'freizeit', monthlyLimit: 100),
    ];
    final transactions = [expense('a', 'lebensmittel', 30), expense('b', 'freizeit', 90)];

    final progress = computeBudgetProgress(budgets, categories, transactions);
    expect(progress.first.category.id, 'freizeit');
    expect(progress.last.category.id, 'lebensmittel');
  });

  test('ratio ist 0 wenn kein Limit gesetzt ist', () {
    final budgets = [Budget(categoryId: 'lebensmittel', monthlyLimit: 0)];
    final transactions = [expense('a', 'lebensmittel', 30)];
    final progress = computeBudgetProgress(budgets, categories, transactions);
    expect(progress.first.ratio, 0);
  });
}
