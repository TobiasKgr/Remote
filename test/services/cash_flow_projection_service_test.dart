import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/cash_flow_projection_service.dart';
import 'package:finance_analyzer/services/recurring_payment_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var counter = 0;
  Transaction tx(DateTime date, double amount, String description) {
    return Transaction(id: 't${counter++}', date: date, amount: amount, description: description, categoryId: 'sonstiges');
  }

  group('nextOccurrence', () {
    test('wöchentlich addiert 7 Tage', () {
      expect(nextOccurrence(DateTime(2026, 1, 1), RecurrenceRhythm.weekly), DateTime(2026, 1, 8));
    });

    test('monatlich behält den Tag bei, wenn möglich', () {
      expect(nextOccurrence(DateTime(2026, 1, 15), RecurrenceRhythm.monthly), DateTime(2026, 2, 15));
    });

    test('monatlich kappt auf den letzten Tag des Zielmonats', () {
      expect(nextOccurrence(DateTime(2026, 1, 31), RecurrenceRhythm.monthly), DateTime(2026, 2, 28));
    });

    test('jährlich addiert 12 Monate', () {
      expect(nextOccurrence(DateTime(2026, 3, 10), RecurrenceRhythm.yearly), DateTime(2027, 3, 10));
    });
  });

  group('computeCashFlowProjection', () {
    test('ohne wiederkehrende Zahlungen bleibt der Saldo über den ganzen Zeitraum konstant', () {
      final points = computeCashFlowProjection(currentBalance: 1000, recurringGroups: const [], referenceDate: DateTime(2026, 1, 1));
      expect(points, hasLength(1));
      expect(points.first.balance, 1000);
    });

    test('projiziert eine monatliche Ausgabe an ihrem nächsten fälligen Tag', () {
      final group = RecurringPaymentGroup(
        description: 'Netflix.com',
        rhythm: RecurrenceRhythm.monthly,
        transactions: [tx(DateTime(2026, 1, 15), -12.99, 'Netflix.com')],
      );
      final points = computeCashFlowProjection(
        currentBalance: 1000,
        recurringGroups: [group],
        referenceDate: DateTime(2026, 1, 20),
        daysAhead: 30,
      );

      expect(points.last.balance, closeTo(1000 - 12.99, 0.001));
      expect(points.last.eventDescription, contains('Netflix'));
      expect(points.last.date, DateTime(2026, 2, 15));
    });

    test('mehrere Fälligkeiten im Fenster werden alle angewendet und akkumulieren sich', () {
      final group = RecurringPaymentGroup(
        description: 'Miete',
        rhythm: RecurrenceRhythm.monthly,
        transactions: [tx(DateTime(2026, 1, 1), -800, 'Miete')],
      );
      final points = computeCashFlowProjection(
        currentBalance: 2000,
        recurringGroups: [group],
        referenceDate: DateTime(2026, 1, 1),
        daysAhead: 70,
      );

      // Fällig am 1. Feb und 1. Mrz innerhalb von 70 Tagen.
      expect(points.length, 3);
      expect(points.last.balance, closeTo(2000 - 800 - 800, 0.001));
    });

    test('mehrere gleichzeitig fällige Zahlungen erzeugen je einen Punkt am selben Tag', () {
      final groups = [
        RecurringPaymentGroup(description: 'Netflix.com', rhythm: RecurrenceRhythm.monthly, transactions: [tx(DateTime(2026, 1, 15), -12.99, 'Netflix.com')]),
        RecurringPaymentGroup(description: 'Spotify', rhythm: RecurrenceRhythm.monthly, transactions: [tx(DateTime(2026, 1, 15), -9.99, 'Spotify')]),
      ];
      final points = computeCashFlowProjection(currentBalance: 500, recurringGroups: groups, referenceDate: DateTime(2026, 1, 20), daysAhead: 30);

      expect(points.length, 3); // Startpunkt + 2 Ereignisse am 15. Februar
      expect(points[1].date, DateTime(2026, 2, 15));
      expect(points[2].date, DateTime(2026, 2, 15));
      expect(points.last.balance, closeTo(500 - 12.99 - 9.99, 0.001));
    });

    test('Ereignisse außerhalb des Zeitfensters werden nicht berücksichtigt', () {
      final group = RecurringPaymentGroup(
        description: 'Versicherung',
        rhythm: RecurrenceRhythm.yearly,
        transactions: [tx(DateTime(2025, 6, 1), -300, 'Versicherung')],
      );
      final points = computeCashFlowProjection(currentBalance: 100, recurringGroups: [group], referenceDate: DateTime(2026, 1, 1), daysAhead: 56);

      expect(points, hasLength(1));
      expect(points.first.balance, 100);
    });
  });
}
