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

  Budget defaultBudget(String categoryId, double limit) {
    return Budget(id: Budget.defaultId(categoryId), categoryId: categoryId, monthlyLimit: limit);
  }

  Budget overrideBudget(String categoryId, int year, int month, double limit) {
    return Budget(id: Budget.overrideId(categoryId, year, month), categoryId: categoryId, monthlyLimit: limit, year: year, month: month);
  }

  Transaction expense(String id, String categoryId, double amount, {DateTime? date}) {
    return Transaction(id: id, date: date ?? DateTime(2026, 7, 1), amount: -amount, description: id, categoryId: categoryId);
  }

  group('resolveEffectiveBudget', () {
    test('nimmt Standard-Budget wenn keine Abweichung existiert', () {
      final budgets = [defaultBudget('lebensmittel', 300)];
      final effective = resolveEffectiveBudget(budgets, 'lebensmittel', 2026, 7);
      expect(effective?.monthlyLimit, 300);
    });

    test('Abweichung für den Monat hat Vorrang vor dem Standard', () {
      final budgets = [defaultBudget('lebensmittel', 300), overrideBudget('lebensmittel', 2026, 12, 500)];
      expect(resolveEffectiveBudget(budgets, 'lebensmittel', 2026, 12)?.monthlyLimit, 500);
      expect(resolveEffectiveBudget(budgets, 'lebensmittel', 2026, 7)?.monthlyLimit, 300);
    });

    test('gibt null zurück wenn weder Standard noch Abweichung existiert', () {
      expect(resolveEffectiveBudget([], 'lebensmittel', 2026, 7), isNull);
    });
  });

  group('computeBudgetProgress (Monat)', () {
    test('berechnet Ausgaben je Budget-Kategorie', () {
      final budgets = [defaultBudget('lebensmittel', 300)];
      final transactions = [expense('a', 'lebensmittel', 120), expense('b', 'lebensmittel', 50)];

      final progress = computeBudgetProgress(budgets, categories, transactions, 2026, 7);
      expect(progress, hasLength(1));
      expect(progress.first.spent, 170);
      expect(progress.first.limit, 300);
      expect(progress.first.ratio, closeTo(170 / 300, 0.0001));
    });

    test('nutzt die Monats-Abweichung statt des Standards', () {
      final budgets = [defaultBudget('lebensmittel', 300), overrideBudget('lebensmittel', 2026, 12, 500)];
      final transactions = [expense('a', 'lebensmittel', 400, date: DateTime(2026, 12, 1))];

      final progress = computeBudgetProgress(budgets, categories, transactions, 2026, 12);
      expect(progress.first.limit, 500);
      expect(progress.first.ratio, closeTo(400 / 500, 0.0001));
    });

    test('Kategorien ohne Budget werden nicht aufgeführt', () {
      final budgets = [defaultBudget('lebensmittel', 300)];
      final transactions = [expense('a', 'freizeit', 50)];

      final progress = computeBudgetProgress(budgets, categories, transactions, 2026, 7);
      expect(progress, hasLength(1));
      expect(progress.first.spent, 0);
    });

    test('gelöschte Kategorie wird ignoriert', () {
      final budgets = [Budget(id: 'geloescht', categoryId: 'geloescht', monthlyLimit: 100)];
      final progress = computeBudgetProgress(budgets, categories, [], 2026, 7);
      expect(progress, isEmpty);
    });

    test('sortiert absteigend nach Auslastung (ratio)', () {
      final budgets = [defaultBudget('lebensmittel', 100), defaultBudget('freizeit', 100)];
      final transactions = [expense('a', 'lebensmittel', 30), expense('b', 'freizeit', 90)];

      final progress = computeBudgetProgress(budgets, categories, transactions, 2026, 7);
      expect(progress.first.category.id, 'freizeit');
      expect(progress.last.category.id, 'lebensmittel');
    });

    test('ratio ist 0 wenn kein Limit gesetzt ist', () {
      final budgets = [defaultBudget('lebensmittel', 0)];
      final transactions = [expense('a', 'lebensmittel', 30)];
      final progress = computeBudgetProgress(budgets, categories, transactions, 2026, 7);
      expect(progress, isEmpty);
    });
  });

  group('computeYearlyBudgetProgress', () {
    test('summiert effektive Monatslimits über das ganze Jahr', () {
      // 300/Monat, aber im Dezember 500 statt 300 -> 11*300 + 500 = 3800
      final budgets = [defaultBudget('lebensmittel', 300), overrideBudget('lebensmittel', 2026, 12, 500)];
      final transactions = [
        expense('a', 'lebensmittel', 100, date: DateTime(2026, 1, 1)),
        expense('b', 'lebensmittel', 450, date: DateTime(2026, 12, 1)),
      ];

      final progress = computeYearlyBudgetProgress(budgets, categories, transactions, 2026);
      expect(progress, hasLength(1));
      expect(progress.first.limit, 3800);
      expect(progress.first.spent, 550);
    });

    test('Kategorie ohne Planwert im ganzen Jahr wird nicht aufgeführt', () {
      final progress = computeYearlyBudgetProgress([], categories, [], 2026);
      expect(progress, isEmpty);
    });
  });
}
