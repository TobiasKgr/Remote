import 'package:finance_analyzer/services/targobank_finanzstatus_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Nachgebildeter Auszug einer TARGOBANK "Finanzstatus"-PDF: Zeilenumbrüche
  // und das Fehlen von Leerzeichen entsprechen dem, was die PDF-Text-
  // Extraktion aus der echten mehrspaltigen Tabelle macht (Betrag und
  // laufender Kontostand landen direkt hintereinander ohne Trennzeichen).
  const sampleText = 'TARGOBANK AG - Postfach 10 02 30 - 47002 Duisburg\n'
      'F I N A N Z S T A T U S vom 01.03.2026 - 31.03.2026Informationen über Ihre Konten\n'
      'MonatsübersichtAlle Transaktionen Ihres Girokontos\n'
      'IBAN:DE02 3002 0900 5330 9009 16BIC CODE:CMCIDEDDTransaktionen\n'
      'DatumTagBuchungstextAusgabenEinnahmenGuthaben/Kredit\n'
      '28.02FR1.000,00ANFANGSSALDO\n'
      '02.03MO50,00950,00SEPALASTSCHRIFTMusterVersicherungAGVertrag12345\n'
      '03.03DI377,19RESERV.BETRAGPOSEUR9,86AUTORISIERUNGSNRKARTENNUMMEREdekaMusterBeckumDE\n'
      '03.03DI950,00 -HINWEISLIMITÜBERZIEHUNGEINLÖSUNGERFOLGTETROTZFEHLENDERDECKUNG\n'
      '05.03DO2.000,002.950,00LOHN/GEHALT/RENTEMusterGmbHLohnAbrechnung02/2026\n'
      '31.03DI2.950,00ENDSALDODieser Finanzstatus ist gleichzeitig Ihr Kontoauszug\n'
      'Haben Sie Fragen oder Anmerkungen zu Ihrem Finanzstatus?';

  test('erkennt eine TARGOBANK-Finanzstatus-PDF anhand ihrer Kopfzeilen', () {
    expect(looksLikeTargobankFinanzstatus(sampleText), isTrue);
    expect(looksLikeTargobankFinanzstatus('Irgendein anderer Kontoauszug'), isFalse);
  });

  test('leitet Ausgabe/Einnahme aus der Saldo-Änderung zwischen den Zeilen ab, statt aus dem Betrag', () {
    final result = parseTargobankFinanzstatus(sampleText);

    expect(result, hasLength(2));

    expect(result[0].date, DateTime(2026, 3, 2));
    expect(result[0].amount, closeTo(-50.00, 0.001));
    expect(result[0].description, contains('SEPALASTSCHRIFT'));

    expect(result[1].date, DateTime(2026, 3, 5));
    expect(result[1].amount, closeTo(2000.00, 0.001));
    expect(result[1].description, contains('LOHN/GEHALT/RENTE'));
  });

  test('reservierte Kartenbeträge (RESERV.BETRAGPOS) und Überziehungshinweise (HINWEIS) werden übersprungen', () {
    final result = parseTargobankFinanzstatus(sampleText);
    expect(result.any((r) => r.description.contains('RESERV.BETRAGPOS')), isFalse);
    expect(result.any((r) => r.description.contains('HINWEIS')), isFalse);
  });

  test('ein Buchungsdatum aus dem Vormonat/-jahr (Übertrag vom letzten Tag) bekommt das richtige Jahr', () {
    const textWithYearWrap = 'TARGOBANK AG\n'
        'F I N A N Z S T A T U S vom 01.01.2026 - 31.01.2026\n'
        'IBAN:DE02 3002 0900 5330 9009 16BIC CODE:CMCIDEDDTransaktionen\n'
        'DatumTagBuchungstextAusgabenEinnahmenGuthaben/Kredit\n'
        '31.12MI500,00ANFANGSSALDO\n'
        '02.01FR100,00400,00SEPALASTSCHRIFTMusterMiete\n'
        '31.01SA400,00ENDSALDO';

    final result = parseTargobankFinanzstatus(textWithYearWrap);
    expect(result, hasLength(1));
    expect(result.single.date, DateTime(2026, 1, 2));
  });

  test('leerer/nicht erkannter Text liefert eine leere Liste statt zu crashen', () {
    expect(parseTargobankFinanzstatus(''), isEmpty);
    expect(parseTargobankFinanzstatus('Beliebiger Text ohne Tabellenstruktur'), isEmpty);
  });
}
