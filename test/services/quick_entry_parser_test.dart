import 'package:finance_analyzer/services/quick_entry_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reference = DateTime(2026, 3, 20);

  test('erkennt Betrag, Beschreibung und "gestern"', () {
    final draft = parseQuickEntry('50€ Rewe gestern', referenceDate: reference);
    expect(draft, isNotNull);
    expect(draft!.amount, 50);
    expect(draft.isIncome, isFalse);
    expect(draft.date, DateTime(2026, 3, 19));
    expect(draft.description, 'Rewe');
  });

  test('erkennt Komma-Dezimalbeträge und "vorgestern"', () {
    final draft = parseQuickEntry('12,99 Netflix vorgestern', referenceDate: reference);
    expect(draft, isNotNull);
    expect(draft!.amount, 12.99);
    expect(draft.date, DateTime(2026, 3, 18));
    expect(draft.description, 'Netflix');
  });

  test('ohne Datumsangabe wird "heute" verwendet', () {
    final draft = parseQuickEntry('30 Tanken', referenceDate: reference);
    expect(draft, isNotNull);
    expect(draft!.date, DateTime(2026, 3, 20));
    expect(draft.description, 'Tanken');
  });

  test('führendes Plus markiert eine Einnahme', () {
    final draft = parseQuickEntry('+120€ Erstattung heute', referenceDate: reference);
    expect(draft, isNotNull);
    expect(draft!.isIncome, isTrue);
    expect(draft.amount, 120);
  });

  test('explizites Datum im Format dd.mm. wird erkannt', () {
    final draft = parseQuickEntry('20 Tanken 15.03.', referenceDate: reference);
    expect(draft, isNotNull);
    expect(draft!.date, DateTime(2026, 3, 15));
    expect(draft.description, 'Tanken');
  });

  test('explizites Datum mit Jahr wird erkannt', () {
    final draft = parseQuickEntry('20 Tanken 15.03.2025', referenceDate: reference);
    expect(draft, isNotNull);
    expect(draft!.date, DateTime(2025, 3, 15));
  });

  test('ohne erkennbaren Betrag wird null geliefert', () {
    expect(parseQuickEntry('Rewe gestern', referenceDate: reference), isNull);
    expect(parseQuickEntry('', referenceDate: reference), isNull);
  });

  test('ohne verbleibenden Text wird ein Platzhalter als Beschreibung verwendet', () {
    final draft = parseQuickEntry('25€', referenceDate: reference);
    expect(draft, isNotNull);
    expect(draft!.description, 'Buchung');
  });
}
