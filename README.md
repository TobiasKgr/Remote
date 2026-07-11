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
- Gehaltsnachweis-PDF-Import: eigener Parser für Brutto/Netto/Steuern/Sozialversicherung,
  Review-Formular, eigene "Gehalt"-Übersicht (Brutto-vs-Netto-Chart pro Jahr), optionale
  Verknüpfung mit einer Einnahme-Buchung
- Zweite Person im Haushalt: Personen anlegen/verwalten (über "Kategorien" → Personen-Icon),
  Buchungen und Gehaltsabrechnungen optional einer Person zuordnen (sonst "Gemeinsam"),
  Filterleiste (Alle/Gemeinsam/pro Person) auf Dashboard, Buchungen, Jahresübersicht und Gehalt
- Lokale Speicherung (Hive), keine Cloud/kein Server nötig

Noch offen (nächste Ausbaustufen, siehe unten):

- Automatische Optimierungsvorschläge (z. B. "Abo X seit 3 Monaten ungenutzt")
- Firmenwagen-Modul (geldwerter Vorteil, Leasingrate, Kraftstoff getrennt auswerten)

## Architektur

- **Flutter/Dart**, Zielplattformen: `android`, `ios`, `web`, `windows`, `macos`, `linux`
- **State Management**: Riverpod (`flutter_riverpod`)
- **Persistenz**: Hive (`hive` + `hive_flutter`), läuft ohne Server/Backend, auch im Web (IndexedDB)
- **PDF-Textextraktion**: `syncfusion_flutter_pdf` (Community-Lizenz, siehe Hinweis unten)
- **Diagramme**: `fl_chart`

```
lib/
  models/         Category, Subcategory, Transaction, SalarySlip, Person (+ Hive TypeAdapter)
  data/           Hive-Setup, Standard-Kategorien (Seed-Daten)
  repositories/   CRUD auf den Hive-Boxen
  providers/      Riverpod-Provider/Notifier, Monats-/Jahresfilter, Personen-Filter
  services/       Auto-Kategorisierung (Keyword-Matching), PDF-Import-Parser
                  (Kontoauszug), Gehaltsabrechnungs-Parser
  screens/        Dashboard, Buchungen, Import, Gehalt, Kategorien, Personen, Jahresübersicht
  widgets/        Wiederverwendbare UI-Bausteine (Charts, Summary-Cards, Personen-Filterleiste, ...)
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

## Gehaltsnachweis-Import

Analog zum Kontoauszug-Import gibt es im Tab **Gehalt** einen eigenen,
ebenfalls heuristischen Parser (`lib/services/salary_slip_parser_service.dart`)
für Lohn-/Gehaltsabrechnungen:

- Sucht nach bekannten deutschen Lohnabrechnungs-Begriffen
  ("Gesamt-Brutto", "Auszahlungsbetrag", "Lohnsteuer", "Kirchensteuer",
  "Solidaritätszuschlag", "Kranken-/Renten-/Arbeitslosen-/Pflegeversicherung")
  und nimmt den am Zeilenende stehenden Betrag.
- Erkennt den Abrechnungsmonat entweder aus einem deutschen Monatsnamen
  ("Juli 2026") oder dem Format `MM/JJJJ`.
- Alle erkannten Werte landen in einem Review-Formular; "Sonstige Abzüge"
  wird automatisch als Brutto − Netto − Steuern − Sozialversicherung berechnet.
- Eine Gehaltsabrechnung ist ein reiner Detail-/Aufschlüsselungsdatensatz
  (`SalarySlip`) und zählt **nicht automatisch** zu den Einnahmen im
  Dashboard. Über den Schalter "Auch als Einnahme in Buchungen erfassen"
  wird optional eine verknüpfte Netto-Buchung angelegt/aktualisiert – so wird
  vermieden, dass ein bereits aus dem Kontoauszug importierter Gehaltseingang
  doppelt gezählt wird.

Passt das PDF-Layout eines Arbeitgebers/einer Lohnsoftware nicht auf dieses
Muster, muss der Regex/die Keyword-Liste in `SalarySlipParserService`
erweitert werden – die Werte lassen sich aber jederzeit auch manuell im
Formular eintragen oder korrigieren.

## Zweite Person im Haushalt

Über das Personen-Icon oben rechts im **Kategorien**-Tab lassen sich beliebig
viele Haushaltsmitglieder anlegen (Name + Farbe). Danach:

- Jede Buchung (manuell, PDF-Import) und jede Gehaltsabrechnung kann optional
  einer Person zugeordnet werden. Ohne Zuordnung gilt ein Eintrag als
  **"Gemeinsam"**.
- Solange keine Person angelegt ist, ist die gesamte Personen-UI (Dropdown,
  Filterleiste) unsichtbar – Ein-Personen-Haushalte sehen keine zusätzliche
  Komplexität.
- Auf Dashboard, Buchungen, Jahresübersicht und Gehalt erscheint dann eine
  Filterleiste ("Alle" / "Gemeinsam" / je Person), mit der zwischen
  gemeinsamer und getrennter Auswertung umgeschaltet werden kann.
- Löscht man eine Person, bleiben ihre bisherigen Buchungen/Abrechnungen
  erhalten, gelten danach aber als "Gemeinsam".

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

1. **Optimierungsvorschläge**: Regelwerk, das z. B. mehrfach erkannte Abos,
   Ausgabenspitzen oder Kategorien mit starkem Anstieg gegenüber dem
   Vormonat/-jahr erkennt und als Hinweiskarte auf dem Dashboard anzeigt.
2. **Firmenwagen**: eigenes Modul für geldwerten Vorteil, Leasingrate,
   Kraftstoffkosten getrennt von privaten KFZ-Kosten, inkl. Auswirkung auf die
   Gehalts-Gegenrechnung.
