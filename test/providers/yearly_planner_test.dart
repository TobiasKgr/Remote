import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/yearly_planner_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = [
    Category(id: 'income', name: 'Einkommen', type: CategoryType.income, colorValue: 0xFF00FF00),
    Category(id: 'wohnen', name: 'Wohnen', type: CategoryType.expense, colorValue: 0xFF8B4513),
    Category(id: 'lebensmittel', name: 'Lebensmittel', type: CategoryType.expense, colorValue: 0xFFFF9800),
  ];

  Transaction income(int month, int day) => Transaction(
        id: 'gehalt_$month',
        date: DateTime(2026, month, day),
        amount: 3000,
        description: 'Gehalt T.',
        categoryId: 'income',
        isRecurring: true,
      );

  Transaction miete(int month) => Transaction(
        id: 'miete_$month',
        date: DateTime(2026, month, 1),
        amount: -750,
        description: 'Miete',
        categoryId: 'wohnen',
        isRecurring: true,
      );

  test('gruppiert Buchungen mit gleichem normalisierten Text zu einer Zeile und summiert je Monat', () {
    final transactions = [
      income(1, 1),
      miete(1),
      Transaction(id: 'rewe1', date: DateTime(2026, 1, 5), amount: -50, description: 'REWE SAGT DANKE 1234', categoryId: 'lebensmittel'),
      Transaction(id: 'rewe2', date: DateTime(2026, 1, 20), amount: -30, description: 'REWE SAGT DANKE 5678', categoryId: 'lebensmittel'),
    ];

    final data = computeYearlyPlanner(transactions, categories);

    final lebensmittelGroup = data.expenseGroups.firstWhere((g) => g.category.id == 'lebensmittel');
    expect(lebensmittelGroup.rows, hasLength(1));
    expect(lebensmittelGroup.rows.single.monthlyAmounts[0], 80);
    expect(lebensmittelGroup.rows.single.yearTotal, 80);
    // Latest (day 20) booking's day becomes the row's "Termin".
    expect(lebensmittelGroup.rows.single.dueDay, 20);
  });

  test('Ausgaben-Beträge sind immer positive Beträge (Magnitude), Einnahmen bleiben positiv', () {
    final data = computeYearlyPlanner([income(1, 1), miete(1)], categories);
    final wohnenGroup = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen');
    expect(wohnenGroup.rows.single.monthlyAmounts[0], 750);

    final incomeGroup = data.incomeGroups.firstWhere((g) => g.category.id == 'income');
    expect(incomeGroup.rows.single.monthlyAmounts[0], 3000);
  });

  test('Monats- und Jahressummen sind über alle Serien korrekt aggregiert', () {
    final transactions = [income(1, 1), income(2, 1), income(3, 1), miete(1), miete(2), miete(3)];
    final data = computeYearlyPlanner(transactions, categories);

    expect(data.monthlyIncomeTotals[0], 3000);
    expect(data.monthlyIncomeTotals[1], 3000);
    expect(data.monthlyIncomeTotals[2], 3000);
    expect(data.monthlyIncomeTotals[3], 0);
    expect(data.yearIncomeTotal, 9000);

    expect(data.monthlyExpenseTotals[0], 750);
    expect(data.yearExpenseTotal, 2250);
  });

  test('Prozentanteil einer Zeile bezieht sich auf die Jahressumme der eigenen Sektion (Einnahmen/Ausgaben getrennt)', () {
    final transactions = [
      income(1, 1),
      miete(1),
      Transaction(id: 'strom', date: DateTime(2026, 1, 10), amount: -250, description: 'Stadtwerke', categoryId: 'wohnen'),
    ];
    final data = computeYearlyPlanner(transactions, categories);

    // Gesamtausgaben = 750 + 250 = 1000, Miete-Anteil = 75%.
    final wohnenGroup = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen');
    final mieteRow = wohnenGroup.rows.firstWhere((r) => r.label == 'Miete');
    expect(mieteRow.percentOfTotal, closeTo(0.75, 0.0001));

    // Einnahmen-Anteil bleibt unabhängig von den Ausgaben bei 100%.
    final incomeRow = data.incomeGroups.single.rows.single;
    expect(incomeRow.percentOfTotal, closeTo(1.0, 0.0001));
  });

  test('Umbuchungen zwischen eigenen Konten werden komplett ausgeschlossen', () {
    final transactions = [
      income(1, 1),
      Transaction(
        id: 'transfer_out',
        date: DateTime(2026, 1, 15),
        amount: -200,
        description: 'Umbuchung zu Sparkonto',
        categoryId: 'umbuchung',
        isTransfer: true,
        transferGroupId: 'g1',
      ),
      Transaction(
        id: 'transfer_in',
        date: DateTime(2026, 1, 15),
        amount: 200,
        description: 'Umbuchung von Girokonto',
        categoryId: 'umbuchung',
        isTransfer: true,
        transferGroupId: 'g1',
      ),
    ];
    final data = computeYearlyPlanner(transactions, categories);

    expect(data.expenseGroups, isEmpty);
    expect(data.yearIncomeTotal, 3000);
  });

  test('gelöschte Kategorie fällt in eine "Unbekannt"-Gruppe statt zu crashen', () {
    final transactions = [
      Transaction(id: 't1', date: DateTime(2026, 1, 1), amount: -20, description: 'Alte Buchung', categoryId: 'geloescht'),
    ];
    final data = computeYearlyPlanner(transactions, categories);

    expect(data.expenseGroups, hasLength(1));
    expect(data.expenseGroups.single.category.name, 'Unbekannt');
    expect(data.expenseGroups.single.category.type, CategoryType.expense);
  });

  test('leere Buchungsliste liefert leere Gruppen und Nullsummen', () {
    final data = computeYearlyPlanner([], categories);
    expect(data.incomeGroups, isEmpty);
    expect(data.expenseGroups, isEmpty);
    expect(data.yearIncomeTotal, 0);
    expect(data.yearExpenseTotal, 0);
    expect(data.monthlyIncomeTotals, List.filled(12, 0));
  });
}
