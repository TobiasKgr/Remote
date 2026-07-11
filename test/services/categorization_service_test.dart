import 'package:finance_analyzer/data/default_categories.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/categorization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = buildDefaultCategories();
  final service = CategorizationService(categories);

  test('erkennt Streaming-Abo anhand von Schlüsselwort', () {
    final match = service.suggest('NETFLIX.COM 4569871');
    expect(match, isNotNull);
    expect(match!.categoryId, 'fixkosten');
    expect(match.subcategoryId, 'fixkosten_streaming');
  });

  test('erkennt Supermarkt anhand von Schlüsselwort, case-insensitive', () {
    final match = service.suggest('REWE SAGT DANKE');
    expect(match!.categoryId, 'lebensmittel');
    expect(match.subcategoryId, 'lebensmittel_supermarkt');
  });

  test('gibt null zurück wenn kein Schlüsselwort passt', () {
    final match = service.suggest('Unbekannte Buchung XY123');
    expect(match, isNull);
  });

  test('fallbackCategoryId liefert Einkommenskategorie für Einnahmen', () {
    expect(service.fallbackCategoryId(true), 'income');
  });

  test('fallbackCategoryId liefert Sonstiges für Ausgaben', () {
    expect(service.fallbackCategoryId(false), 'sonstiges');
  });

  test('längster passender Schlüsselbegriff gewinnt bei Mehrdeutigkeit', () {
    final ambiguousCategories = [
      ...buildDefaultCategories(),
    ];
    // "amazon" (Elektronik) und "amazon prime" (Streaming) matchen beide -
    // der längere/spezifischere Begriff soll gewinnen.
    final match = CategorizationService(ambiguousCategories).suggest('AMAZON PRIME MONATSABO');
    expect(match!.subcategoryId, 'fixkosten_streaming');
  });

  test('gelernte Historie hat Vorrang vor Keyword-Matching', () {
    final history = [
      Transaction(
        id: 'h1',
        date: DateTime(2026, 5, 1),
        amount: -12.99,
        description: 'Netflix.com Rechnung 1234',
        categoryId: 'sonstiges',
        subcategoryId: 'sonstiges_diverses',
      ),
      Transaction(
        id: 'h2',
        date: DateTime(2026, 6, 1),
        amount: -12.99,
        description: 'Netflix.com Rechnung 5678',
        categoryId: 'sonstiges',
        subcategoryId: 'sonstiges_diverses',
      ),
    ];
    final learningService = CategorizationService(categories, history: history);
    final match = learningService.suggest('Netflix.com Rechnung 9999');
    expect(match!.categoryId, 'sonstiges');
    expect(match.subcategoryId, 'sonstiges_diverses');
  });

  test('Historie ignoriert Beschreibungen mit unterschiedlichem Text', () {
    final history = [
      Transaction(
        id: 'h1',
        date: DateTime(2026, 5, 1),
        amount: -12.99,
        description: 'Netflix.com Rechnung 1234',
        categoryId: 'sonstiges',
      ),
    ];
    final learningService = CategorizationService(categories, history: history);
    final match = learningService.suggest('Spotify Premium');
    expect(match!.categoryId, 'fixkosten');
    expect(match.subcategoryId, 'fixkosten_streaming');
  });

  test('Historie ohne Treffer für unbekannte Kategorie-ID wird ignoriert', () {
    final history = [
      Transaction(
        id: 'h1',
        date: DateTime(2026, 5, 1),
        amount: -12.99,
        description: 'Sonderfall Buchung 1',
        categoryId: 'geloeschte_kategorie',
      ),
    ];
    final learningService = CategorizationService(categories, history: history);
    final match = learningService.suggest('Sonderfall Buchung 2');
    expect(match, isNull);
  });
}
