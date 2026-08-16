import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/recurring_payment_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final detector = RecurringPaymentDetector();
  var counter = 0;
  Transaction tx(DateTime date, double amount, String description, {bool isTransfer = false}) {
    return Transaction(
      id: 't${counter++}',
      date: date,
      amount: amount,
      description: description,
      categoryId: 'sonstiges',
      isTransfer: isTransfer,
    );
  }

  test('erkennt eine monatliche Zahlung (Netflix) über mehrere Monate hinweg', () {
    final transactions = [
      tx(DateTime(2026, 1, 15), -12.99, 'Netflix.com Rechnung 1'),
      tx(DateTime(2026, 2, 15), -12.99, 'Netflix.com Rechnung 2'),
      tx(DateTime(2026, 3, 15), -12.99, 'Netflix.com Rechnung 3'),
      tx(DateTime(2026, 4, 16), -12.99, 'Netflix.com Rechnung 4'),
    ];

    final result = detector.detect(transactions);
    expect(result, hasLength(1));
    expect(result.single.rhythm, RecurrenceRhythm.monthly);
    expect(result.single.occurrenceCount, 4);
    expect(result.single.lastDate, DateTime(2026, 4, 16));
    expect(result.single.latestAmount, closeTo(-12.99, 0.001));
  });

  test('erkennt eine wöchentliche Zahlung', () {
    final transactions = [
      tx(DateTime(2026, 1, 5), -5.00, 'Wochenmarkt Abo'),
      tx(DateTime(2026, 1, 12), -5.00, 'Wochenmarkt Abo'),
      tx(DateTime(2026, 1, 19), -5.00, 'Wochenmarkt Abo'),
      tx(DateTime(2026, 1, 26), -5.00, 'Wochenmarkt Abo'),
    ];

    final result = detector.detect(transactions);
    expect(result, hasLength(1));
    expect(result.single.rhythm, RecurrenceRhythm.weekly);
  });

  test('erkennt eine jährliche Zahlung', () {
    final transactions = [
      tx(DateTime(2024, 6, 1), -250.00, 'KFZ Versicherung Jahresbeitrag'),
      tx(DateTime(2025, 6, 3), -250.00, 'KFZ Versicherung Jahresbeitrag'),
      tx(DateTime(2026, 5, 30), -250.00, 'KFZ Versicherung Jahresbeitrag'),
    ];

    final result = detector.detect(transactions);
    expect(result, hasLength(1));
    expect(result.single.rhythm, RecurrenceRhythm.yearly);
  });

  test('toleriert eine leichte Preiserhöhung (innerhalb ±5%) als dieselbe Serie', () {
    final transactions = [
      tx(DateTime(2026, 1, 15), -9.99, 'Spotify Premium'),
      tx(DateTime(2026, 2, 15), -9.99, 'Spotify Premium'),
      tx(DateTime(2026, 3, 15), -10.39, 'Spotify Premium'), // +4% Preiserhöhung
    ];

    final result = detector.detect(transactions);
    expect(result, hasLength(1));
    expect(result.single.occurrenceCount, 3);
    expect(result.single.hasPriceChange, isTrue);
    expect(result.single.priceChangeAmount, closeTo(0.40, 0.001));
  });

  test('gleichbleibender Betrag wird nicht als Preisänderung markiert', () {
    final transactions = [
      tx(DateTime(2026, 1, 15), -12.99, 'Netflix.com'),
      tx(DateTime(2026, 2, 15), -12.99, 'Netflix.com'),
      tx(DateTime(2026, 3, 15), -12.99, 'Netflix.com'),
    ];
    final result = detector.detect(transactions);
    expect(result.single.hasPriceChange, isFalse);
    expect(result.single.priceChangeAmount, closeTo(0, 0.001));
  });

  test('unterschiedliche Beträge trennen die Serie (z.B. wöchentlicher Einkauf ist kein Abo)', () {
    final transactions = [
      tx(DateTime(2026, 1, 5), -42.17, 'Rewe Sagt Danke'),
      tx(DateTime(2026, 1, 12), -18.50, 'Rewe Sagt Danke'),
      tx(DateTime(2026, 1, 19), -63.90, 'Rewe Sagt Danke'),
      tx(DateTime(2026, 1, 26), -27.30, 'Rewe Sagt Danke'),
    ];

    final result = detector.detect(transactions);
    expect(result, isEmpty);
  });

  test('unregelmäßiger Abstand wird nicht als wiederkehrend erkannt', () {
    final transactions = [
      tx(DateTime(2026, 1, 3), -20.00, 'Gelegenheitskauf XY'),
      tx(DateTime(2026, 1, 4), -20.00, 'Gelegenheitskauf XY'),
      tx(DateTime(2026, 6, 20), -20.00, 'Gelegenheitskauf XY'),
    ];

    final result = detector.detect(transactions);
    expect(result, isEmpty);
  });

  test('weniger als die Mindestanzahl an Buchungen wird nicht erkannt', () {
    final transactions = [
      tx(DateTime(2026, 1, 15), -12.99, 'Netflix.com'),
      tx(DateTime(2026, 2, 15), -12.99, 'Netflix.com'),
    ];
    expect(detector.detect(transactions), isEmpty);
  });

  test('Umbuchungen zwischen eigenen Konten werden ignoriert', () {
    final transactions = [
      tx(DateTime(2026, 1, 15), -500.00, 'Umbuchung Tagesgeld', isTransfer: true),
      tx(DateTime(2026, 2, 15), -500.00, 'Umbuchung Tagesgeld', isTransfer: true),
      tx(DateTime(2026, 3, 15), -500.00, 'Umbuchung Tagesgeld', isTransfer: true),
    ];
    expect(detector.detect(transactions), isEmpty);
  });

  test('leere Buchungsliste liefert eine leere Liste', () {
    expect(detector.detect([]), isEmpty);
  });

  test('mehrere unabhängige Serien werden alle erkannt, neuestes Datum zuerst', () {
    final transactions = [
      tx(DateTime(2026, 1, 15), -12.99, 'Netflix.com'),
      tx(DateTime(2026, 2, 15), -12.99, 'Netflix.com'),
      tx(DateTime(2026, 3, 15), -12.99, 'Netflix.com'),
      tx(DateTime(2026, 1, 20), -9.99, 'Spotify Premium'),
      tx(DateTime(2026, 2, 20), -9.99, 'Spotify Premium'),
      tx(DateTime(2026, 3, 21), -9.99, 'Spotify Premium'),
    ];

    final result = detector.detect(transactions);
    expect(result, hasLength(2));
    expect(result.first.description, contains('Spotify'));
    expect(result.last.description, contains('Netflix'));
  });
}
