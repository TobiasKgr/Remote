import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/providers/transaction_filter_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Transaction tx(String id, String description, double amount, String categoryId) {
    return Transaction(id: id, date: DateTime(2026, 7, 1), amount: amount, description: description, categoryId: categoryId);
  }

  final transactions = [
    tx('a', 'REWE SAGT DANKE', -45.67, 'lebensmittel'),
    tx('b', 'Netflix.com', -12.99, 'fixkosten'),
    tx('c', 'Gehalt Muster GmbH', 2500, 'income'),
    tx('d', 'Restaurant Adria', -89.50, 'lebensmittel'),
  ];

  test('ohne Filter werden alle Buchungen zurückgegeben', () {
    expect(filterTransactions(transactions), hasLength(4));
  });

  test('Suchtext filtert case-insensitiv nach Beschreibung', () {
    final result = filterTransactions(transactions, query: 'netflix');
    expect(result.map((t) => t.id), ['b']);
  });

  test('Suchtext ohne Treffer liefert leere Liste', () {
    expect(filterTransactions(transactions, query: 'aldi'), isEmpty);
  });

  test('Kategorie-Filter schränkt auf eine Kategorie ein', () {
    final result = filterTransactions(transactions, categoryId: 'lebensmittel');
    expect(result.map((t) => t.id).toSet(), {'a', 'd'});
  });

  test('Betrag von/bis filtert nach Absolutbetrag', () {
    final result = filterTransactions(transactions, minAmount: 40, maxAmount: 90);
    expect(result.map((t) => t.id).toSet(), {'a', 'd'});
  });

  test('nur Betrag von (kein Maximum) schließt kleinere Beträge aus', () {
    final result = filterTransactions(transactions, minAmount: 100);
    expect(result.map((t) => t.id), ['c']);
  });

  test('Filter lassen sich kombinieren', () {
    final result = filterTransactions(transactions, categoryId: 'lebensmittel', minAmount: 50);
    expect(result.map((t) => t.id), ['d']);
  });

  test('AmountRange.isActive erkennt gesetzte Grenzen', () {
    expect(const AmountRange().isActive, isFalse);
    expect(const AmountRange(min: 10).isActive, isTrue);
    expect(const AmountRange(max: 10).isActive, isTrue);
  });
}
