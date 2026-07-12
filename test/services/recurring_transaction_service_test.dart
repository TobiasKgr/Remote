import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/recurring_transaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = RecurringTransactionService();

  Transaction tx({
    required String id,
    required DateTime date,
    double amount = -12.99,
    String description = 'Netflix',
    String categoryId = 'fixkosten',
    String? subcategoryId = 'fixkosten_streaming',
    bool isRecurring = true,
    String? personId,
  }) {
    return Transaction(
      id: id,
      date: date,
      amount: amount,
      description: description,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      isRecurring: isRecurring,
      personId: personId,
    );
  }

  test('generiert die fehlende Buchung für den Folgemonat', () {
    final transactions = [tx(id: 'a', date: DateTime(2026, 6, 15))];
    final generated = service.generateMissingOccurrences(transactions, referenceDate: DateTime(2026, 7, 20));

    expect(generated, hasLength(1));
    expect(generated.first.date, DateTime(2026, 7, 15));
    expect(generated.first.amount, -12.99);
    expect(generated.first.categoryId, 'fixkosten');
    expect(generated.first.subcategoryId, 'fixkosten_streaming');
    expect(generated.first.source, TransactionSource.recurringGenerated);
    expect(generated.first.isRecurring, isTrue);
  });

  test('generiert nichts wenn der aktuelle Monat schon eine Buchung hat', () {
    final transactions = [tx(id: 'a', date: DateTime(2026, 7, 15))];
    final generated = service.generateMissingOccurrences(transactions, referenceDate: DateTime(2026, 7, 20));
    expect(generated, isEmpty);
  });

  test('holt mehrere fehlende Monate nach, wenn die App länger nicht geöffnet war', () {
    final transactions = [tx(id: 'a', date: DateTime(2026, 4, 15))];
    final generated = service.generateMissingOccurrences(transactions, referenceDate: DateTime(2026, 7, 1));

    expect(generated.map((t) => t.date), [DateTime(2026, 5, 15), DateTime(2026, 6, 15), DateTime(2026, 7, 15)]);
  });

  test('generiert nichts wenn die jüngste Buchung der Serie nicht mehr wiederkehrend ist', () {
    final transactions = [
      tx(id: 'a', date: DateTime(2026, 5, 15)),
      tx(id: 'b', date: DateTime(2026, 6, 15), isRecurring: false), // Abo gekündigt
    ];
    final generated = service.generateMissingOccurrences(transactions, referenceDate: DateTime(2026, 7, 1));
    expect(generated, isEmpty);
  });

  test('begrenzt den Tag auf die tatsächliche Monatslänge (z. B. 31. -> Februar)', () {
    final transactions = [tx(id: 'a', date: DateTime(2026, 1, 31))];
    final generated = service.generateMissingOccurrences(transactions, referenceDate: DateTime(2026, 2, 15));

    expect(generated, hasLength(1));
    expect(generated.first.date, DateTime(2026, 2, 28));
  });

  test('trennt Serien nach Kategorie, Unterkategorie und Person', () {
    final transactions = [
      tx(id: 'a', date: DateTime(2026, 6, 1), description: 'Streaming', personId: 'alice'),
      tx(id: 'b', date: DateTime(2026, 6, 1), description: 'Streaming', personId: 'bob'),
    ];
    final generated = service.generateMissingOccurrences(transactions, referenceDate: DateTime(2026, 7, 1));

    expect(generated, hasLength(2));
    expect(generated.map((t) => t.personId).toSet(), {'alice', 'bob'});
  });

  test('verschiedene Beschreibungen bilden getrennte Serien', () {
    final transactions = [
      tx(id: 'a', date: DateTime(2026, 6, 1), description: 'Netflix'),
      tx(id: 'b', date: DateTime(2026, 6, 1), description: 'Spotify'),
    ];
    final generated = service.generateMissingOccurrences(transactions, referenceDate: DateTime(2026, 7, 1));
    expect(generated, hasLength(2));
  });

  test('keine Buchungen -> keine Generierung', () {
    expect(service.generateMissingOccurrences([], referenceDate: DateTime(2026, 7, 1)), isEmpty);
  });
}
