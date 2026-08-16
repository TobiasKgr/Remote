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

  test('Quartals-Rechnungsabschluss-Layout: kein Zeilenumbruch zwischen Buchungen, '
      'Betrag+Saldo stehen am Zeilenende statt am Anfang, Tag.Monat hat einen Punkt', () {
    // Bei manchen Finanzstatus-PDFs (beobachtet beim quartalsweisen
    // "Rechnungsabschluss" Ende März/Juni/September/Dezember) liefert die
    // PDF-Text-Extraktion pro Seite praktisch keine Zeilenumbrüche mehr, und
    // Betrag+Saldo stehen hinter statt vor dem Buchungstext.
    const noNewlineText = 'TARGOBANK AG F I N A N Z S T A T U S vom 01.06.2026 - 30.06.2026 '
        'Transaktionen DatumTagBuchungstextBelastungenGutschriftenGuthaben/Kredit '
        '31.05.SOANFANGSSALDO1.000,00'
        '01.06.MORESERV. BETRAG POS EUR 76,98AUTORISIERUNGSNR 592636KARTENNUMMERtoom BM Warendorf DE1.000,00'
        '01.06.MOAUSFÜHRUNG DAUERAUFTRAG AUFTRAGSNUMMER 0300007 MIETE KONRAD-ADENAUER-RING915,0085,00'
        '15.06.MOLOHN / GEHALT / RENTEWibbelt GmbHAbrechnung 05/20262.165,112.250,11'
        '30.06.DIENDSALDO2.250,11'
        'Guthaben/Kredit';

    final result = parseTargobankFinanzstatus(noNewlineText);

    expect(result, hasLength(2));
    expect(result[0].date, DateTime(2026, 6, 1));
    expect(result[0].amount, closeTo(-915.00, 0.001));
    expect(result[0].description, contains('MIETE'));
    expect(result[1].date, DateTime(2026, 6, 15));
    expect(result[1].amount, closeTo(2165.11, 0.001));
    expect(result[1].description, contains('LOHN'));
  });

  test('parseTargobankFinanzstatusDetailed liefert Anfangs- und Endsaldo zusätzlich zu den Buchungen', () {
    final result = parseTargobankFinanzstatusDetailed(sampleText);

    expect(result.transactions, hasLength(2));
    expect(result.openingBalanceSum, closeTo(1000.00, 0.001));
    expect(result.closingBalanceSum, closeTo(2950.00, 0.001));

    // Anfangssaldo + Buchungen ergibt den Endsaldo (-50 + 2000 = 1950 = 2950 - 1000).
    final bookedTotal = result.transactions.fold<double>(0, (s, t) => s + t.amount);
    expect(bookedTotal, closeTo(result.closingBalanceSum! - result.openingBalanceSum!, 0.001));
  });

  test('mehrere Kontenabschnitte: Anfangs-/Endsalden werden über alle Abschnitte aufsummiert', () {
    const twoAccountsText = 'TARGOBANK AG\n'
        'F I N A N Z S T A T U S vom 01.03.2026 - 31.03.2026\n'
        'IBAN:DE02 3002 0900 5330 9009 16BIC CODE:CMCIDEDDTransaktionen\n'
        'DatumTagBuchungstextAusgabenEinnahmenGuthaben/Kredit\n'
        '28.02FR1.000,00ANFANGSSALDO\n'
        '02.03MO50,00950,00SEPALASTSCHRIFTMusterVersicherungAGVertrag12345\n'
        '31.03DI950,00ENDSALDO\n'
        'IBAN:DE17 3002 0900 5281 2973 68BIC CODE:CMCIDEDDTransaktionen\n'
        'DatumTagBuchungstextAusgabenEinnahmenGuthaben/Kredit\n'
        '01.03SO3.000,00ANFANGSSALDO\n'
        '31.03DI3.000,00ENDSALDO';

    final result = parseTargobankFinanzstatusDetailed(twoAccountsText);

    expect(result.openingBalanceSum, closeTo(1000.00 + 3000.00, 0.001));
    expect(result.closingBalanceSum, closeTo(950.00 + 3000.00, 0.001));
  });

  test('fehlt eine Buchung im erkannten Layout, stimmt Anfangssaldo + Buchungen nicht mehr mit dem Endsaldo überein', () {
    // Bewusst eine Buchungszeile in einem Format, das keine der beiden
    // unterstützten Reihenfolgen (Betrag zuerst/zuletzt) trifft, damit sie
    // unerkannt bleibt - simuliert einen Layout-Fall, den der Parser noch
    // nicht abdeckt.
    const textWithGap = 'TARGOBANK AG\n'
        'F I N A N Z S T A T U S vom 01.03.2026 - 31.03.2026\n'
        'IBAN:DE02 3002 0900 5330 9009 16BIC CODE:CMCIDEDDTransaktionen\n'
        'DatumTagBuchungstextAusgabenEinnahmenGuthaben/Kredit\n'
        '28.02FR1.000,00ANFANGSSALDO\n'
        '02.03MO ??? nicht erkennbare Zeile ??? \n'
        '31.03DI2.950,00ENDSALDO';

    final result = parseTargobankFinanzstatusDetailed(textWithGap);

    expect(result.transactions, isEmpty);
    expect(result.openingBalanceSum, closeTo(1000.00, 0.001));
    expect(result.closingBalanceSum, closeTo(2950.00, 0.001));
    // 0 (nichts gebucht) != 2950 - 1000 = 1950 -> die Differenz muss auffallen.
    expect(result.closingBalanceSum! - result.openingBalanceSum!, isNot(closeTo(0, 0.001)));
  });
}
