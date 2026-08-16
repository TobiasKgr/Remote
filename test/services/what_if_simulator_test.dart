import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/recurring_payment_detector.dart';
import 'package:finance_analyzer/services/what_if_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var counter = 0;
  Transaction tx(DateTime date, double amount, String description) {
    return Transaction(id: 't${counter++}', date: date, amount: amount, description: description, categoryId: 'sonstiges');
  }

  RecurringPaymentGroup group(RecurrenceRhythm rhythm, double amount) {
    return RecurringPaymentGroup(
      description: 'Test',
      rhythm: rhythm,
      transactions: [for (var i = 0; i < 3; i++) tx(DateTime(2026, i + 1, 1), amount, 'Test')],
    );
  }

  test('rechnet die monatliche Ersparnis über den Simulationszeitraum hoch', () {
    final result = computeWhatIfSavings(cancelledGroups: [group(RecurrenceRhythm.monthly, -12.99)], months: 12);
    expect(result.monthlySavings, closeTo(12.99, 0.01));
    expect(result.totalSavings, closeTo(12.99 * 12, 0.01));
    expect(result.months, 12);
  });

  test('summiert mehrere gekündigte Abos auf unterschiedlichen Rhythmen', () {
    final groups = [
      group(RecurrenceRhythm.monthly, -12.99),
      group(RecurrenceRhythm.yearly, -120.00), // 10.00/Monat
    ];
    final result = computeWhatIfSavings(cancelledGroups: groups, months: 6);
    expect(result.monthlySavings, closeTo(12.99 + 10.00, 0.01));
    expect(result.totalSavings, closeTo((12.99 + 10.00) * 6, 0.01));
  });

  test('Einnahmen-Serien zählen nicht als Ersparnis', () {
    final result = computeWhatIfSavings(cancelledGroups: [group(RecurrenceRhythm.monthly, 3000)], months: 12);
    expect(result.monthlySavings, 0);
    expect(result.totalSavings, 0);
  });

  test('ohne ausgewählte Abos ist die Ersparnis 0', () {
    final result = computeWhatIfSavings(cancelledGroups: const [], months: 12);
    expect(result.monthlySavings, 0);
    expect(result.totalSavings, 0);
  });
}
