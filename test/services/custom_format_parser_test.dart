import 'package:finance_analyzer/models/custom_import_profile.dart';
import 'package:finance_analyzer/services/custom_format_parser.dart';
import 'package:flutter_test/flutter_test.dart';

CustomImportProfile _profile({
  ImportDateFormat dateFormat = ImportDateFormat.ddMMyyyy,
  ImportAmountPosition amountPosition = ImportAmountPosition.endOfLine,
  ImportDecimalSeparator decimalSeparator = ImportDecimalSeparator.comma,
}) {
  return CustomImportProfile(
    id: 'p1',
    name: 'Test-Bank',
    dateFormat: dateFormat,
    amountPosition: amountPosition,
    decimalSeparator: decimalSeparator,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('erkennt eine Zeile mit Betrag am Ende und Komma-Dezimaltrennzeichen', () {
    final text = '15.03.2026 REWE SAGT DANKE -45,67\n16.03.2026 GEHALT 3.000,00 H';
    final result = parseWithCustomProfile(text, _profile());

    expect(result, hasLength(2));
    expect(result[0].date, DateTime(2026, 3, 15));
    expect(result[0].description, 'REWE SAGT DANKE');
    expect(result[0].amount, closeTo(-45.67, 0.001));
    expect(result[1].amount, closeTo(3000.00, 0.001));
    expect(result[1].description, 'GEHALT');
  });

  test('erkennt Betrag direkt nach dem Datum', () {
    final text = '15.03.2026 -45,67 REWE SAGT DANKE\n16.03.2026 3.000,00 H GEHALT';
    final result = parseWithCustomProfile(text, _profile(amountPosition: ImportAmountPosition.afterDate));

    expect(result, hasLength(2));
    expect(result[0].amount, closeTo(-45.67, 0.001));
    expect(result[0].description, 'REWE SAGT DANKE');
    expect(result[1].amount, closeTo(3000.00, 0.001));
    expect(result[1].description, 'GEHALT');
  });

  test('zweistelliges Jahr wird als 20xx interpretiert', () {
    final text = '15.03.26 Tanken -50,00';
    final result = parseWithCustomProfile(text, _profile(dateFormat: ImportDateFormat.ddMMyy));
    expect(result.single.date, DateTime(2026, 3, 15));
  });

  test('Punkt als Dezimaltrennzeichen wird korrekt geparst', () {
    final text = '15.03.2026 Tanken -50.00';
    final result = parseWithCustomProfile(text, _profile(decimalSeparator: ImportDecimalSeparator.dot));
    expect(result.single.amount, closeTo(-50.00, 0.001));
  });

  test('ohne Vorzeichen/Marker wird als unsichere Ausgabe markiert', () {
    final text = '15.03.2026 Unklare Buchung 12,00';
    final result = parseWithCustomProfile(text, _profile());
    expect(result.single.amount, -12.00);
    expect(result.single.amountAmbiguous, isTrue);
  });

  test('funktioniert auch ohne Zeilenumbrüche (durchgehender Fließtext)', () {
    const text = '15.03.2026REWE SAGT DANKE-45,6716.03.2026GEHALT3.000,00H';
    final result = parseWithCustomProfile(text, _profile());
    expect(result, hasLength(2));
    expect(result[0].amount, closeTo(-45.67, 0.001));
    expect(result[1].amount, closeTo(3000.00, 0.001));
  });

  test('Zeile ohne erkennbaren Betrag wird übersprungen', () {
    final text = '15.03.2026 Nur Text ohne Betrag\n16.03.2026 Tanken -50,00';
    final result = parseWithCustomProfile(text, _profile());
    expect(result, hasLength(1));
    expect(result.single.description, 'Tanken');
  });

  test('leerer Text liefert eine leere Liste', () {
    expect(parseWithCustomProfile('', _profile()), isEmpty);
  });
}
