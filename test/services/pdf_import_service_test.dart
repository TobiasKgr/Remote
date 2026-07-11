import 'package:finance_analyzer/services/pdf_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = PdfImportService();

  test('parst einzeilige Buchung mit explizitem Minus', () {
    final result = service.parse('01.03.2024 REWE SAGT DANKE 3141 -45,67');
    expect(result, hasLength(1));
    expect(result.first.date, DateTime(2024, 3, 1));
    expect(result.first.description, 'REWE SAGT DANKE 3141');
    expect(result.first.amount, closeTo(-45.67, 0.001));
    expect(result.first.amountAmbiguous, isFalse);
  });

  test('parst einzeilige Buchung mit explizitem Plus als Einnahme', () {
    final result = service.parse('03.03.2024 GEHALT MUSTER GMBH +2.500,00');
    expect(result, hasLength(1));
    expect(result.first.amount, closeTo(2500.00, 0.001));
    expect(result.first.amountAmbiguous, isFalse);
  });

  test('parst Soll/Haben-Format (S = Ausgabe, H = Einnahme)', () {
    final result = service.parse(
      '05.03.2024 Miete Musterstraße 1.200,00 S\n'
      '06.03.2024 Gehaltseingang 2.500,00 H',
    );
    expect(result, hasLength(2));
    expect(result[0].amount, closeTo(-1200.00, 0.001));
    expect(result[1].amount, closeTo(2500.00, 0.001));
  });

  test('führt mehrzeilige Buchungen (umgebrochene Beschreibung) zusammen', () {
    final result = service.parse(
      '10.03.2024 Dauerauftrag\n'
      'Netflix.com Streaming Abo\n'
      '-12,99',
    );
    expect(result, hasLength(1));
    expect(result.first.description, 'Dauerauftrag Netflix.com Streaming Abo');
    expect(result.first.amount, closeTo(-12.99, 0.001));
  });

  test('markiert Betrag ohne Vorzeichen als ambig und nimmt Ausgabe an', () {
    final result = service.parse('12.03.2024 Unklare Buchung 99,99');
    expect(result, hasLength(1));
    expect(result.first.amount, closeTo(-99.99, 0.001));
    expect(result.first.amountAmbiguous, isTrue);
  });

  test('ignoriert Zeilen ohne erkennbares Datum am Anfang', () {
    final result = service.parse('Kontoauszug Nr. 3 Seite 1 von 2\nIBAN DE00 0000 0000 0000 00');
    expect(result, isEmpty);
  });
}
