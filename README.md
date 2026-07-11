# Finanzen

Cross-platform Finanz-App (Flutter): Windows-exe, Android, iOS und Web aus einer
Codebasis. Kontoauszüge und Gehaltsnachweise als PDF einlesen, Buchungen
kategorisieren (inkl. Abos), Gehalt gegenrechnen, Monats- und Jahresübersicht.

## Stand: MVP

Umgesetzt:

- Manuelle Eingabe von Buchungen (Einnahme/Ausgabe, Kategorie, Unterkategorie)
- Kategorien & Unterkategorien frei verwaltbar (z. B. "Fixkosten & Abos" → "Streaming-Abos")
- PDF-Import von Kontoauszügen mit automatischer Kategorisierungs-Vorschlag und
  Review-Screen vor dem Speichern
- Monatsübersicht (Einnahmen/Ausgaben/Saldo, Ausgaben nach Kategorie als Kreisdiagramm)
- Jahresübersicht (Einnahmen/Ausgaben pro Monat als Balkendiagramm, Jahres-Kategorieauswertung)
- Lokale Speicherung (Hive), keine Cloud/kein Server nötig

Noch offen (nächste Ausbaustufen, siehe unten):

- Gehaltsnachweis-PDF speziell auswerten (Netto/Brutto-Aufschlüsselung)
- Automatische Optimierungsvorschläge (z. B. "Abo X seit 3 Monaten ungenutzt")
- Zweite Person im Haushalt (getrennte/gemeinsame Auswertung)
- Firmenwagen-Modul (geldwerter Vorteil, Leasingrate, Kraftstoff getrennt auswerten)

## Architektur

- **Flutter/Dart**, Zielplattformen: `android`, `ios`, `web`, `windows`, `macos`, `linux`
- **State Management**: Riverpod (`flutter_riverpod`)
- **Persistenz**: Hive (`hive` + `hive_flutter`), läuft ohne Server/Backend, auch im Web (IndexedDB)
- **PDF-Textextraktion**: `syncfusion_flutter_pdf` (Community-Lizenz, siehe Hinweis unten)
- **Diagramme**: `fl_chart`

```
lib/
  models/         Category, Subcategory, Transaction (+ Hive TypeAdapter)
  data/           Hive-Setup, Standard-Kategorien (Seed-Daten)
  repositories/   CRUD auf den Hive-Boxen
  providers/      Riverpod-Provider/Notifier, Monats-/Jahresfilter
  services/       Auto-Kategorisierung (Keyword-Matching), PDF-Import-Parser
  screens/        Dashboard, Buchungen, Import, Kategorien, Jahresübersicht
  widgets/        Wiederverwendbare UI-Bausteine (Charts, Summary-Cards, ...)
```

## Wichtiger Hinweis zum PDF-Import

Banken exportieren Kontoauszüge in völlig unterschiedlichen PDF-Layouts – es
gibt keinen einheitlichen Standard. Der Import-Parser (`lib/services/pdf_import_service.dart`)
ist eine **Heuristik** für gängige deutsche Kontoauszug-Formate:

- Er sucht pro Zeile nach einem Datum am Anfang (`TT.MM.JJJJ`) und einem Betrag
  am Ende (deutsches Komma-Format), inkl. Soll/Haben-Kennzeichen (`S`/`H`) oder
  explizitem `+`/`-`.
- Zeilen ohne Betrag werden als Fortsetzung der Buchungsbeschreibung interpretiert
  (typisch bei umgebrochenen Verwendungszwecken).
- Wird kein Vorzeichen erkannt, wird die Zeile als Ausgabe angenommen und im
  Import-Review-Screen gelb markiert – **jede importierte Buchung muss vor dem
  Speichern im Review-Screen geprüft werden.**

Passt das PDF-Layout einer bestimmten Bank nicht auf dieses Muster, muss der
Regex in `PdfImportService` erweitert werden (z. B. um weitere Datums- oder
Betragsformate).

**Lizenzhinweis**: `syncfusion_flutter_pdf` ist über die kostenlose Syncfusion
Community License nutzbar (u. a. für Einzelpersonen und kleine Unternehmen mit
< 1 Mio. USD Jahresumsatz). Für eine geplante kommerzielle Veröffentlichung
sollte das vor Release geprüft werden (https://www.syncfusion.com/sales/communitylicense).

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter test

# Ausführen
flutter run -d chrome      # Web
flutter run -d windows     # Windows-exe (unter Windows)
flutter run -d macos       # macOS
flutter run                # verbundenes Android/iOS-Gerät oder Emulator
```

Builds für die Distribution:

```bash
flutter build apk          # Android
flutter build ios          # iOS (erfordert macOS + Xcode)
flutter build windows      # Windows .exe
flutter build web          # Web (statische Dateien in build/web)
```

## Roadmap / nächste Schritte

1. **Gehaltsnachweis-PDF-Import**: eigener Parser für Lohn-/Gehaltsabrechnungen
   (Brutto, Netto, Abzüge) als Ergänzung zum Kontoauszug-Import.
2. **Optimierungsvorschläge**: Regelwerk, das z. B. mehrfach erkannte Abos,
   Ausgabenspitzen oder Kategorien mit starkem Anstieg gegenüber dem
   Vormonat/-jahr erkennt und als Hinweiskarte auf dem Dashboard anzeigt.
3. **Zweite Person im Haushalt**: `Person`-Modell, Zuordnung von Buchungen zu
   einer Person, gemeinsame und getrennte Auswertungssicht.
4. **Firmenwagen**: eigenes Modul für geldwerten Vorteil, Leasingrate,
   Kraftstoffkosten getrennt von privaten KFZ-Kosten, inkl. Auswirkung auf die
   Gehalts-Gegenrechnung.
