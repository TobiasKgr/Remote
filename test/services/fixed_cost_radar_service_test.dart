import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/fixed_cost_radar_service.dart';
import 'package:finance_analyzer/services/recurring_payment_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var counter = 0;
  Transaction tx(DateTime date, double amount, String description) {
    return Transaction(id: 't${counter++}', date: date, amount: amount, description: description, categoryId: 'sonstiges');
  }

  RecurringPaymentGroup group(RecurrenceRhythm rhythm, double amount, {int count = 3}) {
    return RecurringPaymentGroup(
      description: 'Test',
      rhythm: rhythm,
      transactions: [for (var i = 0; i < count; i++) tx(DateTime(2026, i + 1, 1), amount, 'Test')],
    );
  }

  test('rechnet wöchentliche und jährliche Abos auf einen Monatsdurchschnitt um und summiert sie', () {
    final groups = [
      group(RecurrenceRhythm.monthly, -12.99), // bleibt 12.99
      group(RecurrenceRhythm.weekly, -5.00), // 5*52/12 = 21.67
      group(RecurrenceRhythm.yearly, -120.00), // 120/12 = 10.00
    ];
    final result = computeFixedCostRadar(recurringGroups: groups, allTransactions: const []);
    expect(result.monthlyFixedCosts, closeTo(12.99 + (5.00 * 52 / 12) + 10.00, 0.01));
  });

  test('Einnahmen-Serien (positiver Betrag) fließen nicht in die Fixkosten ein', () {
    final groups = [group(RecurrenceRhythm.monthly, 3000.00)]; // Gehalt, keine Ausgabe
    final result = computeFixedCostRadar(recurringGroups: groups, allTransactions: const []);
    expect(result.monthlyFixedCosts, 0);
  });

  test('mittleres monatliches Einkommen wird nur über Monate mit tatsächlichen Einnahmen gebildet', () {
    final transactions = [
      tx(DateTime(2026, 1, 1), 3000, 'Gehalt'),
      tx(DateTime(2026, 2, 1), 3200, 'Gehalt'),
      tx(DateTime(2026, 3, 1), -50, 'Ausgabe'), // zählt nicht als Einkommen
    ];
    final income = computeAverageMonthlyIncome(transactions, referenceDate: DateTime(2026, 3, 15), lookbackMonths: 6);
    expect(income, closeTo((3000 + 3200) / 2, 0.01));
  });

  test('Umbuchungen zählen nicht als Einkommen', () {
    final transactions = [
      Transaction(id: 'x', date: DateTime(2026, 1, 1), amount: 500, description: 'Umbuchung', categoryId: 'umbuchung', isTransfer: true),
    ];
    final income = computeAverageMonthlyIncome(transactions, referenceDate: DateTime(2026, 1, 15));
    expect(income, 0);
  });

  test('Anteil (ratio) ergibt sich aus Fixkosten geteilt durch Durchschnittseinkommen', () {
    const result = FixedCostRadarResult(monthlyFixedCosts: 900, averageMonthlyIncome: 3000);
    expect(result.ratio, closeTo(0.3, 0.001));
  });

  test('ohne Einkommen ist der Anteil nicht berechenbar (null statt Division durch 0)', () {
    const result = FixedCostRadarResult(monthlyFixedCosts: 900, averageMonthlyIncome: 0);
    expect(result.ratio, isNull);
  });

  test('Monate außerhalb des Rückblick-Zeitraums werden ignoriert', () {
    final transactions = [
      tx(DateTime(2025, 1, 1), 3000, 'Gehalt altes Jahr'), // zu weit zurück
      tx(DateTime(2026, 3, 1), 3000, 'Gehalt aktuell'),
    ];
    final income = computeAverageMonthlyIncome(transactions, referenceDate: DateTime(2026, 3, 15), lookbackMonths: 3);
    expect(income, closeTo(3000, 0.01));
  });
}
