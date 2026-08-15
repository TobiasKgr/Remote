import 'package:finance_analyzer/services/salary_slip_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = SalarySlipParserService();

  test('parst Brutto, Netto und Abrechnungsmonat (deutscher Monatsname)', () {
    final result = service.parse(
      'Abrechnung für Juli 2026\n'
      'Gesamt-Brutto 4.200,00\n'
      'Lohnsteuer 650,00\n'
      'Solidaritätszuschlag 20,00\n'
      'Krankenversicherung 320,00\n'
      'Rentenversicherung 390,00\n'
      'Arbeitslosenversicherung 55,00\n'
      'Pflegeversicherung 65,00\n'
      'Auszahlungsbetrag 2.700,00',
    );

    expect(result.period, DateTime(2026, 7));
    expect(result.gross, closeTo(4200.00, 0.001));
    expect(result.net, closeTo(2700.00, 0.001));
    expect(result.incomeTax, closeTo(670.00, 0.001));
    expect(result.socialSecurity, closeTo(830.00, 0.001));
  });

  test('parst Abrechnungsmonat im Format MM/JJJJ', () {
    final result = service.parse('Abrechnungszeitraum: 03/2026\nGesamtbrutto 3.000,00');
    expect(result.period, DateTime(2026, 3));
    expect(result.gross, closeTo(3000.00, 0.001));
  });

  test('fehlende Werte bleiben null bzw. 0', () {
    final result = service.parse('Ein Dokument ohne erkennbare Gehaltsangaben');
    expect(result.period, isNull);
    expect(result.gross, isNull);
    expect(result.net, isNull);
    expect(result.incomeTax, 0);
    expect(result.socialSecurity, 0);
  });

  test('DATEV-Layout ohne Betrag neben "Gesamt-Brutto"/"Auszahlungsbetrag": '
      'Brutto aus Lohnart-Komponenten summiert, Netto aus der IBAN-Zeile übernommen', () {
    // Nachgebildeter Zeilenumbruch einer typischen "Abrechnung der
    // Brutto/Netto-Bezüge" (Form.-Nr. LNGN16): Label und Betrag von
    // Gesamt-Brutto/Auszahlungsbetrag stehen wegen der Tabellen-Extraktion
    // auf unterschiedlichen Zeilen, anders als in den anderen Tests oben.
    final result = service.parse(
      'für März 2026\n'
      'Gesamt-BruttoSteuerrechtliche AbzügeNetto-Verdienst\n'
      '2000 Gehalt                                                     L  L  J       4.900,00\n'
      '2410 Privatfahrten                                              L  L  J         136,00\n'
      '3100 AG-Anteil VWL,lfd                                          L  L  J          26,00\n'
      '                                                                              5.062,00\n'
      'TARGOBANK Düsseldorf\n'
      'DE02 3002 0900 5330 9009 16            1.13406                            2.166,11',
    );

    expect(result.period, DateTime(2026, 3));
    expect(result.gross, closeTo(5062.00, 0.001));
    expect(result.net, closeTo(2166.11, 0.001));
  });
}
