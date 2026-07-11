import 'package:finance_analyzer/data/default_categories.dart';
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
}
