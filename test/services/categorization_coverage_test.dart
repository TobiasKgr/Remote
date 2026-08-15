import 'package:finance_analyzer/data/default_categories.dart';
import 'package:finance_analyzer/services/categorization_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A large set of realistic, bank-statement-style transaction descriptions
/// (the kind of noisy text real German account exports contain - "KARTENZAHLUNG",
/// merchant name, city, reference numbers) spanning every default category.
/// This is the concrete, testable stand-in for "99% of bookings should land
/// in a real category, only ~1% in Sonstiges": it doesn't prove anything
/// about a specific user's actual bank data (which this heuristic can't see
/// in advance), but it pins down and protects a high hit rate against a
/// broad, representative sample so a future edit can't quietly regress it.
const _sampleDescriptions = [
  // Einkommen
  'GEHALTSZAHLUNG JULI MUSTERMANN GMBH',
  'LOHN AUGUST 2026 ARBEITGEBER AG',
  'PRAEMIE Q2 2026 AUSZAHLUNG',
  'WEIHNACHTSGELD 2026',
  'RUECKERSTATTUNG VERSICHERUNG REF 88213',
  // Wohnen
  'DAUERAUFTRAG KALTMIETE HAUSVERWALTUNG MUELLER',
  'NEBENKOSTENABRECHNUNG 2025 HAUSGELD',
  'STADTWERKE MUENCHEN ABSCHLAG STROM/GAS',
  'EON ENERGIE DEUTSCHLAND ABSCHLAG',
  'IKEA DEUTSCHLAND GMBH KARTENZAHLUNG',
  'OBI BAUMARKT KARTENZAHLUNG',
  // Fixkosten & Abos
  'NETFLIX.COM 4569871 LASTSCHRIFT',
  'SPOTIFY P1234ABCD LASTSCHRIFT',
  'AMAZON PRIME MONATSABO',
  'DISNEY+ MONATSBEITRAG',
  'DAZN LIMITED LASTSCHRIFT',
  'TELEKOM DEUTSCHLAND GMBH RECHNUNG',
  'VODAFONE GMBH LASTSCHRIFT MOBILFUNK',
  'CONGSTAR RECHNUNG APR 2026',
  'ALLIANZ VERSICHERUNGS-AG BEITRAG',
  'HUK24 KFZ BEITRAG LASTSCHRIFT',
  'MCFIT GYM GMBH MITGLIEDSBEITRAG',
  'URBAN SPORTS CLUB MONATSBEITRAG',
  'MICROSOFT 365 ABO KARTENZAHLUNG',
  'ICLOUD SPEICHER APPLE.COM/BILL',
  // Lebensmittel
  'REWE SAGT DANKE 3141 KARTENZAHLUNG',
  'EDEKA MUSTERMANN E-CENTER',
  'ALDI SUED SAGT DANKE',
  'LIDL SAGT DANKE KARTENZAHLUNG',
  'KAUFLAND STIFTUNG & CO KG',
  'NETTO MARKEN-DISCOUNT SAGT DANKE',
  'BAECKEREI SCHMIDT KARTENZAHLUNG',
  'MCDONALDS DEUTSCHLAND KARTENZAHLUNG',
  'LIEFERANDO.DE BESTELLUNG',
  'STARBUCKS COFFEE KARTENZAHLUNG',
  // Mobilität
  'ARAL TANKSTELLE KARTENZAHLUNG',
  'SHELL DEUTSCHLAND KARTENZAHLUNG',
  'DB VERTRIEB GMBH FAHRKARTE',
  'BVG ABO MONATSKARTE',
  'DEUTSCHLANDTICKET LASTSCHRIFT',
  'ATU AUTO-TEILE-UNGER WERKSTATT',
  'FREE NOW FAHRT KARTENZAHLUNG',
  // Freizeit
  'CINESTAR KINOTICKET KARTENZAHLUNG',
  'EVENTIM TICKET ONLINE',
  'BOOKING.COM RESERVIERUNG',
  'LUFTHANSA FLUGTICKET',
  'AIRBNB PAYMENTS UNTERKUNFT',
  // Shopping
  'ZALANDO SE KARTENZAHLUNG',
  'H&M HENNES & MAURITZ KARTENZAHLUNG',
  'MEDIAMARKT SATURN RETAIL',
  'AMAZON.DE KARTENZAHLUNG BESTELLUNG',
  'DM-DROGERIE MARKT KARTENZAHLUNG',
  'ROSSMANN KARTENZAHLUNG',
  'THALIA BUCHHANDLUNG KARTENZAHLUNG',
  // Gesundheit
  'APOTHEKE AM MARKT KARTENZAHLUNG',
  'DR MED SCHNEIDER PRAXISGEBUEHR',
  'PHYSIOTHERAPIE MUELLER REZEPT',
  'TECHNIKER KRANKENKASSE BEITRAG',
  'AOK BUNDESVERBAND BEITRAG',
  // Bank & Gebühren
  'KONTOFUEHRUNGSGEBUEHR JULI 2026',
  'DISPOZINSEN ABRECHNUNG Q2',
  'KREDITKARTENGEBUEHR JAHRESENTGELT',
  'BAUFINANZIERUNG RATE MUSTERBANK',
  // Bildung & Kinder
  'KINDERGARTEN ELTERNBEITRAG STADT',
  'NACHHILFE SCHUELERHILFE MONATSBEITRAG',
  'UDEMY ONLINE KURS KARTENZAHLUNG',
  // Spenden & Kirche
  'UNICEF DEUTSCHLAND SPENDE',
  'KIRCHENSTEUER FINANZAMT ABBUCHUNG',
  'CARITAS SPENDE ONLINE',
  // Haustiere
  'FRESSNAPF KARTENZAHLUNG TIERBEDARF',
  'TIERARZTPRAXIS DR WEBER RECHNUNG',
  'ZOOPLUS SE ONLINE BESTELLUNG',
];

void main() {
  final service = CategorizationService(buildDefaultCategories());

  test('Kategorisierung erkennt bei einer breiten, realistischen Stichprobe fast immer eine passende Kategorie', () {
    final misses = <String>[];
    for (final description in _sampleDescriptions) {
      if (service.suggest(description) == null) misses.add(description);
    }

    final hitRate = (_sampleDescriptions.length - misses.length) / _sampleDescriptions.length;

    // Not literally 99% (this fixed sample is small enough that one miss
    // moves the number a lot), but the same spirit: only a handful of
    // genuine edge cases should fail to match, never a large chunk.
    expect(
      hitRate,
      greaterThanOrEqualTo(0.97),
      reason: 'Trefferquote nur ${(hitRate * 100).toStringAsFixed(1)}%. Nicht erkannt: ${misses.join(', ')}',
    );
  });

  test('keine Buchung landet fälschlich in der Kategorie "Umbuchung"', () {
    // 'umbuchung' is a system-only category for the account transfer flow
    // and must never be suggested for a normal booking, however its keyword
    // list is empty so this is really just a guard against future edits.
    for (final description in _sampleDescriptions) {
      expect(service.suggest(description)?.categoryId, isNot('umbuchung'));
    }
  });
}
