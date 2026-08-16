import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/yearly_planner_providers.dart';
import 'package:finance_analyzer/services/recurring_payment_detector.dart';
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

    final data = computeYearlyPlanner(transactions, categories, year: 2026);

    final lebensmittelGroup = data.expenseGroups.firstWhere((g) => g.category.id == 'lebensmittel');
    expect(lebensmittelGroup.rows, hasLength(1));
    expect(lebensmittelGroup.rows.single.monthlyAmounts[0], 80);
    expect(lebensmittelGroup.rows.single.yearTotal, 80);
    // Latest (day 20) booking's day becomes the row's "Termin".
    expect(lebensmittelGroup.rows.single.dueDay, 20);
  });

  test('Ausgaben-Beträge sind immer positive Beträge (Magnitude), Einnahmen bleiben positiv', () {
    final data = computeYearlyPlanner([income(1, 1), miete(1)], categories, year: 2026);
    final wohnenGroup = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen');
    expect(wohnenGroup.rows.single.monthlyAmounts[0], 750);

    final incomeGroup = data.incomeGroups.firstWhere((g) => g.category.id == 'income');
    expect(incomeGroup.rows.single.monthlyAmounts[0], 3000);
  });

  test('Monats- und Jahressummen sind über alle Serien korrekt aggregiert', () {
    final transactions = [income(1, 1), income(2, 1), income(3, 1), miete(1), miete(2), miete(3)];
    final data = computeYearlyPlanner(transactions, categories, year: 2026);

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
    final data = computeYearlyPlanner(transactions, categories, year: 2026);

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
    final data = computeYearlyPlanner(transactions, categories, year: 2026);

    expect(data.expenseGroups, isEmpty);
    expect(data.yearIncomeTotal, 3000);
  });

  test('gelöschte Kategorie fällt in eine "Unbekannt"-Gruppe statt zu crashen', () {
    final transactions = [
      Transaction(id: 't1', date: DateTime(2026, 1, 1), amount: -20, description: 'Alte Buchung', categoryId: 'geloescht'),
    ];
    final data = computeYearlyPlanner(transactions, categories, year: 2026);

    expect(data.expenseGroups, hasLength(1));
    expect(data.expenseGroups.single.category.name, 'Unbekannt');
    expect(data.expenseGroups.single.category.type, CategoryType.expense);
  });

  test('leere Buchungsliste liefert leere Gruppen und Nullsummen', () {
    final data = computeYearlyPlanner([], categories, year: 2026);
    expect(data.incomeGroups, isEmpty);
    expect(data.expenseGroups, isEmpty);
    expect(data.yearIncomeTotal, 0);
    expect(data.yearExpenseTotal, 0);
    expect(data.monthlyIncomeTotals, List.filled(12, 0));
  });

  group('Prognose (aus erkannten wiederkehrenden Zahlungen)', () {
    RecurringPaymentGroup mieteGroup({int throughMonth = 6}) {
      return RecurringPaymentGroup(
        description: 'Miete',
        rhythm: RecurrenceRhythm.monthly,
        transactions: [for (var m = 1; m <= throughMonth; m++) miete(m)],
      );
    }

    test('füllt zukünftige, noch nicht gebuchte Monate mit dem letzten bekannten Betrag als Prognose', () {
      final transactions = [for (var m = 1; m <= 6; m++) miete(m)];
      final data = computeYearlyPlanner(
        transactions,
        categories,
        year: 2026,
        recurringGroups: [mieteGroup()],
        referenceDate: DateTime(2026, 7, 15),
      );

      final row = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen').rows.single;
      // Juli (Index 6) bis Dezember (Index 11) sind noch nicht gebucht -> Prognose.
      for (var i = 6; i < 12; i++) {
        expect(row.monthlyAmounts[i], 0, reason: 'Monat $i sollte nicht als tatsächlich gebucht gelten');
        expect(row.forecastAmounts[i], 750, reason: 'Monat $i sollte prognostiziert sein');
        expect(row.combinedAmounts[i], 750);
      }
      // Bereits gebuchte Monate bleiben unverändert (keine Prognose nötig).
      for (var i = 0; i < 6; i++) {
        expect(row.forecastAmounts[i], 0);
        expect(row.combinedAmounts[i], 750);
      }
      expect(row.yearTotal, 750 * 12);
    });

    test('eine echte Buchung überschreibt/verdrängt die Prognose für diesen Monat automatisch', () {
      // August wurde bereits importiert (mit abweichendem Betrag) - die
      // Prognose darf dort nicht mehr greifen, die echte Buchung gewinnt.
      final transactions = [
        for (var m = 1; m <= 6; m++) miete(m),
        Transaction(id: 'miete_8_real', date: DateTime(2026, 8, 1), amount: -770, description: 'Miete', categoryId: 'wohnen'),
      ];
      final data = computeYearlyPlanner(
        transactions,
        categories,
        year: 2026,
        recurringGroups: [mieteGroup()],
        referenceDate: DateTime(2026, 7, 15),
      );

      final row = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen').rows.single;
      expect(row.monthlyAmounts[7], 770); // August (Index 7) ist echt gebucht
      expect(row.forecastAmounts[7], 0);
      expect(row.combinedAmounts[7], 770);
      expect(row.forecastAmounts[6], 750); // Juli bleibt Prognose
    });

    test('vergangene, ungebuchte Monate werden nicht rückwirkend prognostiziert', () {
      // Referenzdatum liegt im April - Januar bis März wurden nie gebucht
      // (z. B. weil das Mietverhältnis erst im April begann) und sollen
      // leer bleiben statt rückwirkend eine Prognose zu erhalten.
      final transactions = [for (var m = 4; m <= 6; m++) miete(m)];
      final data = computeYearlyPlanner(
        transactions,
        categories,
        year: 2026,
        recurringGroups: [
          RecurringPaymentGroup(description: 'Miete', rhythm: RecurrenceRhythm.monthly, transactions: [for (var m = 4; m <= 6; m++) miete(m)]),
        ],
        referenceDate: DateTime(2026, 7, 15),
      );

      final row = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen').rows.single;
      for (var i = 0; i < 3; i++) {
        expect(row.combinedAmounts[i], 0);
      }
    });

    test('eine Serie ohne jede Buchung im gewählten Jahr bekommt trotzdem eine Prognose-Zeile', () {
      // Letzte tatsächliche Buchung war Dezember 2025 - im (noch leeren)
      // Jahr 2026 soll die Serie trotzdem als Prognose auftauchen.
      final group = RecurringPaymentGroup(
        description: 'Miete',
        rhythm: RecurrenceRhythm.monthly,
        transactions: [
          Transaction(id: 'm1', date: DateTime(2025, 10, 1), amount: -750, description: 'Miete', categoryId: 'wohnen'),
          Transaction(id: 'm2', date: DateTime(2025, 11, 1), amount: -750, description: 'Miete', categoryId: 'wohnen'),
          Transaction(id: 'm3', date: DateTime(2025, 12, 1), amount: -750, description: 'Miete', categoryId: 'wohnen'),
        ],
      );
      final data = computeYearlyPlanner(
        const [],
        categories,
        year: 2026,
        recurringGroups: [group],
        referenceDate: DateTime(2026, 1, 15),
      );

      final wohnenGroup = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen');
      final row = wohnenGroup.rows.single;
      expect(row.combinedAmounts[0], 750); // Januar
      expect(row.combinedAmounts[11], 750); // Dezember
      expect(row.yearTotal, 750 * 12);
    });

    test('jährlicher Rhythmus prognostiziert nur den fälligen Monat, nicht jeden Monat', () {
      final group = RecurringPaymentGroup(
        description: 'KFZ Steuer',
        rhythm: RecurrenceRhythm.yearly,
        transactions: [
          Transaction(id: 'k1', date: DateTime(2024, 7, 1), amount: -234, description: 'KFZ Steuer', categoryId: 'wohnen'),
          Transaction(id: 'k2', date: DateTime(2025, 7, 1), amount: -234, description: 'KFZ Steuer', categoryId: 'wohnen'),
          Transaction(id: 'k3', date: DateTime(2025, 7, 3), amount: -234, description: 'KFZ Steuer', categoryId: 'wohnen'),
        ],
      );
      final data = computeYearlyPlanner(
        const [],
        categories,
        year: 2026,
        recurringGroups: [group],
        referenceDate: DateTime(2026, 1, 15),
      );

      final row = data.expenseGroups.firstWhere((g) => g.category.id == 'wohnen').rows.single;
      expect(row.combinedAmounts[6], 234); // Juli
      final othersSum = row.combinedAmounts.asMap().entries.where((e) => e.key != 6).fold<double>(0, (s, e) => s + e.value);
      expect(othersSum, 0);
    });
  });
}
