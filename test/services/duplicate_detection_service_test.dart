import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/duplicate_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final existing = [
    Transaction(id: 't1', date: DateTime(2026, 3, 2), amount: -50.00, description: 'REWE SAGT DANKE 3141', categoryId: 'lebensmittel'),
  ];

  test('gleicher Tag, Betrag und normalisierter Text gilt als Duplikat', () {
    final isDup = isDuplicateBooking(
      date: DateTime(2026, 3, 2),
      amount: -50.00,
      description: 'REWE SAGT DANKE 8827', // andere Belegnummer, gleicher Kerntext
      existing: existing,
    );
    expect(isDup, isTrue);
  });

  test('anderer Betrag gilt nicht als Duplikat', () {
    final isDup = isDuplicateBooking(date: DateTime(2026, 3, 2), amount: -51.00, description: 'REWE SAGT DANKE 3141', existing: existing);
    expect(isDup, isFalse);
  });

  test('anderes Datum gilt nicht als Duplikat', () {
    final isDup = isDuplicateBooking(date: DateTime(2026, 3, 3), amount: -50.00, description: 'REWE SAGT DANKE 3141', existing: existing);
    expect(isDup, isFalse);
  });

  test('anderer Beschreibungstext gilt nicht als Duplikat', () {
    final isDup = isDuplicateBooking(date: DateTime(2026, 3, 2), amount: -50.00, description: 'Netflix.com Rechnung', existing: existing);
    expect(isDup, isFalse);
  });

  test('leere Bestandsliste liefert nie ein Duplikat', () {
    final isDup = isDuplicateBooking(date: DateTime(2026, 3, 2), amount: -50.00, description: 'REWE SAGT DANKE 3141', existing: const []);
    expect(isDup, isFalse);
  });
}
