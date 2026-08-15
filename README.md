# Finanzen

Cross-platform Finanz-App (Flutter): Windows-exe, Android, iOS und Web aus einer
Codebasis. Kontoauszüge und Gehaltsnachweise als PDF einlesen, Buchungen
kategorisieren (inkl. Abos), Gehalt gegenrechnen, Monats- und Jahresübersicht,
Optimierungspotenzial erkennen.

## Stand

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
- Firmenwagen-Modul: Fahrzeuge mit geldwertem Vorteil (informativ) und Eigenanteil verwalten
  (über "Gehalt" → Fahrzeug-Icon), Eigenanteil per Klick als Buchung erfassen, Monats-/
  Jahresauswertung der tatsächlichen Firmenwagen-Kosten
- Optimierungsvorschläge: regelbasiertes "Optimierungspotenzial" auf dem Dashboard
  (mehrere Abos in derselben Unterkategorie, Ausgabenspitzen ggü. dem 3-Monats-Schnitt,
  seit mehreren Monaten unverändert laufende Abos, Summe wiederkehrender Kosten)
- Budgets/Sparziele: Standard-Limit pro Ausgaben-Kategorie plus optionale
  monatsspezifische Abweichungen (z. B. höheres Limit im Dezember), Fortschrittsanzeige
  auf Dashboard (Monat) und Jahresübersicht (Jahressumme) - grün/gelb/rot
- Backup/Export & Import: alle lokalen Daten als JSON-Datei sichern und auf einer
  anderen Installation wieder einspielen
- Ein-/ausschaltbare Erinnerungen: lokale Benachrichtigungen bei Budget-Überschreitung
  oder erkannter Ausgabenspitze, standardmäßig deaktiviert
- Automatische wiederkehrende Buchungen: eine als "wiederkehrend" markierte Buchung
  (z. B. ein Abo) erzeugt beim nächsten App-Start automatisch die fällige(n)
  Buchung(en) für die zwischenzeitlich vergangenen Monate
- Suche & Filter in Buchungen: Volltextsuche nach Beschreibung sowie Filter nach
  Kategorie und Betragsbereich (Von/Bis), zusätzlich zu Monat und Personen-Filter
- Konten-Verwaltung: mehrere Bankkonten mit eigenem (aus Startsaldo + Buchungen
  berechnetem) Kontostand, Buchungen optional einem Konto zuordnen, interne
  Umbuchungen zwischen eigenen Konten zählen nicht doppelt als Ein-/Ausgabe
- Vermögensübersicht: Investments/Depots, Immobilien, sonstige Vermögenswerte und
  Kredite/Schulden manuell erfassen, Netto-Vermögen als Summe aus allen
  Kontoständen plus Vermögenswerten abzüglich Verbindlichkeiten
- Demo-Modus: realistische Beispieldaten über 3 Monate laden (Personen, Konten,
  Buchungen, Firmenwagen, Gehaltsabrechnungen, Vermögenswerte), um alle Funktionen
  ohne eigene Eingaben auszuprobieren, jederzeit gesammelt wieder entfernbar
- Lokale Speicherung (Hive), keine Cloud/kein Server nötig

Damit ist die ursprünglich geplante Feature-Liste sowie die anschließend
gewünschten Erweiterungen vollständig umgesetzt.

## Architektur

- **Flutter/Dart**, Zielplattformen: `android`, `ios`, `web`, `windows`, `macos`, `linux`
- **State Management**: Riverpod (`flutter_riverpod`)
- **Persistenz**: Hive (`hive` + `hive_flutter`), läuft ohne Server/Backend, auch im Web (IndexedDB)
- **PDF-Textextraktion**: `syncfusion_flutter_pdf` (Community-Lizenz, siehe Hinweis unten)
- **Diagramme**: `fl_chart`
- **Lokale Erinnerungen**: `flutter_local_notifications` (Android/iOS/macOS/Linux),
  Browser-Notification-API im Web, kein Windows (siehe Abschnitt "Erinnerungen")

```
lib/
  models/         Category, Subcategory, Transaction, SalarySlip, Person, CompanyCar,
                  Budget, Account, Asset (+ Hive TypeAdapter, + toJson/fromJson für Backups)
  data/           Hive-Setup, Standard-Kategorien (Seed-Daten)
  repositories/   CRUD auf den Hive-Boxen
  providers/      Riverpod-Provider/Notifier, Monats-/Jahresfilter, Personen-Filter,
                  Insights, Budget-Fortschritt, Konto-Fortschritt/-Saldo, Netto-Vermögen
  services/       Auto-Kategorisierung (Keyword-Matching), PDF-Import-Parser
                  (Kontoauszug), Gehaltsabrechnungs-Parser, Optimierungs-Regelwerk,
                  Backup-Export/Import, Demo-Daten, plattformspezifisches Datei-Speichern
  theme/          Zentrales Apple/iOS-inspiriertes App-Theme (Farben, Typografie,
                  Formen, Komponenten-Themes) - siehe Abschnitt "Design"
  screens/        Dashboard, Buchungen, Import, Gehalt, Firmenwagen, Kategorien,
                  Personen, Konten, Vermögensübersicht, Budgets, Backup, Einstellungen,
                  Jahresübersicht
  widgets/        Wiederverwendbare UI-Bausteine (Charts, Summary-Cards, Personen-Filterleiste,
                  Optimierungspotenzial-Karten, Budget-Fortschrittsbalken, iOS-Grouped-List-
                  Bausteine, ...)
```

## Design

Die App ist bewusst so gestaltet, als hätte Apple sie entworfen - Look & Feel
orientiert sich an den iOS Human Interface Guidelines, umgesetzt rein über
Flutters Material-Widgets (kein Wechsel auf Cupertino-Widgets, damit sich die
App auf allen Plattformen identisch verhält):

- **Zentrales Theme** (`lib/theme/app_theme.dart`): eigene Light/Dark-Farbpalette
  aus den iOS-Systemfarben (System Blue, systemGroupedBackground `#F2F2F7` hell /
  `#000000` dunkel, ...), eine an die iOS-Typografie-Skala angelehnte `TextTheme`
  (Large Title, Title 1–3, Headline, Body, Footnote, ...), großzügige Eckenradien
  (12–20px) und durchgängige Komponenten-Themes (AppBar, Card, Buttons, Switches,
  Textfelder, Dialoge, Sheets, Navigation) statt Material-Standardlook.
- **`platform: TargetPlatform.iOS`** ist im Theme fest gesetzt: dadurch nutzt die
  App auf **jeder** Plattform (auch Android/Windows/Web) iOS-Seitenübergänge
  (Swipe-to-go-back) und das Verhalten adaptiver Widgets.
- **iOS-Icons**: Durchgängig `CupertinoIcons` statt Material Icons.
- **iOS-Navigation**: Bottom-Tab-Bar mit Blur/Transluzenz (`BackdropFilter`) und
  Hairline-Trennlinie statt Material-Schatten; jeder Screen zeigt einen großen,
  linksbündigen Titel im Content statt in der (kompakten, halbtransparenten)
  AppBar - die iOS "Large Title"-Optik, ohne eine vollständige Sliver-Nav-Bar
  nachzubauen.
- **iOS-Listen**: Einstellungs-/Verwaltungs-Screens (Konten, Vermögensübersicht,
  Budgets, Personen, Einstellungen, Formulare, ...) nutzen abgesetzte, abgerundete
  Karten-Gruppen mit feinen Trennlinien und grauen Versal-Sektionstiteln - die
  klassische iOS "Grouped Table View". Die zugehörigen Bausteine
  (`AppleLargeTitle`, `AppleSectionHeader`, `AppleGroupedSection`, `AppleCard`,
  `AppleHeroCard`) liegen in `lib/widgets/apple_widgets.dart`.
- **Formulare**: Speichern/Löschen als Textbuttons in der Nav-Bar-Ecke statt
  Fließtext-Buttons, Formularfelder randlos/gefüllt innerhalb der Gruppen-Karten
  (iOS-Formularlook).
- **Konsistente Semantikfarben**: Ein/Ausgaben, Erfolg/Fehler/Warnung greifen
  überall auf dieselben iOS-Systemfarben zurück (`context.appleColors` –
  `AppleSemantics`-Theme-Extension in `lib/theme/app_theme.dart`), Farbwähler
  (Kategorien, Konten, Personen, Vermögenswerte) bieten dieselbe iOS-Palette an.

Da die echte San-Francisco-Schrift Apple-lizenziert ist und in dieser
Sandbox-Umgebung keine Schriften nachgeladen werden können, verwendet die App
weiterhin die jeweilige Plattform-Standardschrift - die "Apple-Optik" kommt
über Größen, Schriftschnitte, Laufweiten, Formen und Layout zustande, nicht
über eine exakte Schriftnachbildung.

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

Die Kategorie-Vorschläge dabei kommen aus `CategorizationService`
(`lib/services/categorization_service.dart`), die zwei Heuristiken kombiniert:

1. **Gelernte Historie**: Wurde eine Buchung mit (nach Entfernen von Ziffern)
   nahezu identischer Beschreibung bereits einmal einer Kategorie zugeordnet
   (manuell oder bei einem früheren Import), wird diese Zuordnung
   wiederverwendet – das hat Vorrang vor den generischen Schlüsselwörtern.
2. **Schlüsselwort-Matching**: Fallback über die in den Unterkategorien
   hinterlegten Suchbegriffe. Bei mehreren Treffern gewinnt der **längste**
   (spezifischste) Begriff, z. B. "amazon prime" statt nur "amazon".

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

Über das Verwaltungsmenü (⋮) im **Kategorien**-Tab → "Personen verwalten"
lassen sich beliebig viele Haushaltsmitglieder anlegen (Name + Farbe). Danach:

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

## Firmenwagen-Modul

Über das Fahrzeug-Icon oben rechts im **Gehalt**-Tab gelangt man zur
Firmenwagen-Verwaltung:

- Pro Fahrzeug werden **geldwerter Vorteil** (1%-Regel o. ä.) und
  **Eigenanteil** je Monat erfasst, optional einer Person zugeordnet.
- Der geldwerte Vorteil ist bewusst **rein informativ**: Er ist in der Regel
  bereits als Sachbezug in der Gehaltsabrechnung enthalten und wird dort
  wieder gegengerechnet, daher fließt er nirgends automatisch in
  Einnahmen-Summen ein (keine Doppelzählung).
- Der Eigenanteil ist eine echte Ausgabe – über den Button "Eigenanteil
  erfassen" wird er als Buchung in der Kategorie **Mobilität → Firmenwagen**
  angelegt und taucht damit ganz normal in Dashboard/Jahresübersicht auf.
- Die Firmenwagen-Seite selbst zeigt zusätzlich die Summe aller Buchungen
  dieser Unterkategorie (Eigenanteil, Kraftstoff, Versicherung, Werkstatt, ...)
  für Monat und Jahr.

## Optimierungsvorschläge

Auf dem **Dashboard** erscheint unterhalb der Kategorie-Auswertung ein
Abschnitt "Optimierungspotenzial", sobald das Regelwerk
(`lib/services/optimization_service.dart`) für den gewählten Monat etwas
findet. Es handelt sich bewusst um **Beobachtungen aus den vorhandenen
Buchungsdaten**, keine Vermutungen über tatsächliche Nutzung:

- **Mehrere Abos in derselben Unterkategorie** (z. B. zwei wiederkehrende
  Buchungen in "Streaming-Abos") – mit Namen und Summe.
- **Ausgabenspitze**: eine Kategorie liegt diesen Monat ≥ 30 % (und mind. 20 €)
  über dem Schnitt der letzten drei Monate.
- **Seit N Monaten unverändert laufendes Abo**: eine wiederkehrende Buchung
  mit gleicher Beschreibung ist seit mindestens 3 aufeinanderfolgenden
  Monaten (bis zum aktuellen) vorhanden.
- **Summe wiederkehrender Kosten** des Monats, als Übersicht.

Die Hinweise respektieren den Personen-Filter und werden pro Regel als
eigene Karte angezeigt; ohne Treffer erscheint der Abschnitt gar nicht.

## Erinnerungen (Benachrichtigungen)

Über das Verwaltungsmenü (⋮) im **Kategorien**-Tab → "Einstellungen" lässt
sich ein Schalter "Erinnerungen" umlegen (standardmäßig **aus** - reines
Opt-in, damit keine Berechtigung ungefragt eingefordert wird). Ist er aktiv,
zeigt die App eine lokale Benachrichtigung, sobald:

- eine Kategorie ihr Budget im aktuell gewählten Monat überschreitet, oder
- das Optimierungs-Regelwerk eine neue Warnung meldet (z. B. eine
  Ausgabenspitze oder mehrere Abos in derselben Unterkategorie).

**Wichtige Einschränkung**: Das sind **lokale, In-App-Erinnerungen**, die nur
ausgelöst werden, während die App geöffnet ist - kein echtes
Hintergrund-Push bei geschlossener App. Das würde pro Plattform zusätzliche
Infrastruktur erfordern (z. B. WorkManager unter Android, BGTaskScheduler
unter iOS, ein Service Worker + Push-Backend im Web), was bewusst außerhalb
des Umfangs bleibt. Genutzt wird `flutter_local_notifications`
(`lib/services/notification_backend_io.dart`), das **kein Windows**
unterstützt - dort bleiben Erinnerungen deaktiviert, auch wenn der Schalter
aktiviert ist. Im Web wird stattdessen direkt die Browser-Notification-API
verwendet (`lib/services/notification_backend_web.dart`), was eine
Berechtigungsabfrage im Browser auslöst. Innerhalb einer App-Sitzung wird
jede erkannte Überschreitung/Warnung nur einmal gemeldet, nicht bei jedem
Neu-Rendern.

## Budgets / Sparziele

Über das Verwaltungsmenü (⋮) im **Kategorien**-Tab → "Budgets verwalten" lässt
sich pro Ausgaben-Kategorie planen:

- Ein **Standard-Limit**, das für jeden Monat gilt.
- Optional eine **Abweichung für einen bestimmten Monat** (z. B. höheres Limit
  im Dezember für Geschenke) - diese hat Vorrang vor dem Standard, sobald man
  im Budgets-Screen zu diesem Monat wechselt und dort etwas einträgt.
- Beide Werte sind jederzeit frei überschreibbar; ein eingetragenes Limit von
  `0` entfernt den jeweiligen Eintrag wieder.

Auf dem **Dashboard** erscheint eine Sektion "Budgets" mit einem
Fortschrittsbalken pro Kategorie mit gesetztem (effektivem) Limit für den
gewählten Monat: grün bis 80 %, gelb ab 80 %, rot bei Überschreitung.
Respektiert den Personen-Filter. Auf der **Jahresübersicht** gibt es
zusätzlich eine Sektion "Jahresbudget": Planwert ist dort die Summe der
effektiven Monatslimits über alle 12 Monate, verglichen mit den tatsächlichen
Jahresausgaben je Kategorie. Kategorien ganz ohne Limit erscheinen in keiner
der beiden Ansichten.

## Backup / Export & Import

Über das Verwaltungsmenü (⋮) im **Kategorien**-Tab → "Backup exportieren/importieren"
lassen sich alle lokal gespeicherten Daten (Buchungen, Kategorien,
Gehaltsabrechnungen, Personen, Firmenwagen, Budgets, Konten, Vermögenswerte/Kredite)
als eine JSON-Datei exportieren und auf einer anderen Installation (oder nach
einer Neuinstallation) wieder importieren:

- **Export**: Auf Mobilgeräten öffnet sich der native "Teilen/Speichern"-Dialog,
  auf Desktop ein Speichern-Dialog, im Web wird die Datei direkt heruntergeladen.
- **Import**: Datei auswählen, danach zeigt ein Bestätigungsdialog, wie viele
  Einträge je Typ enthalten sind. Bestehende Einträge mit gleicher ID werden
  überschrieben ("Merge"), alles andere bleibt unangetastet – ein Import
  löscht also nie stillschweigend vorhandene Daten.

Das Backup-Format ist reines JSON (`lib/services/backup_service.dart`, Feld
`formatVersion` für zukünftige Migrationen) und unabhängig vom internen
Hive-Binärformat, also auch außerhalb der App lesbar.

## Automatische wiederkehrende Buchungen

Jede Buchung lässt sich im Formular als "Wiederkehrend (z. B. Abo)" markieren.
Beim nächsten App-Start prüft `RecurringTransactionService`
(`lib/services/recurring_transaction_service.dart`) alle Buchungen:

- Buchungen werden zu **Serien** gruppiert (Beschreibung ohne Ziffern/Satzzeichen
  + Kategorie + Unterkategorie + Person).
- Nur die **jüngste Buchung** einer Serie entscheidet, ob es weitergeht: ist sie
  als wiederkehrend markiert, werden für alle seither vergangenen Kalendermonate
  bis heute automatisch neue Buchungen erzeugt (gleicher Betrag, gleiche
  Kategorie/Person, gleicher Tag im Monat - bei kürzeren Monaten auf den letzten
  Tag begrenzt).
- Ein Abo **kündigen**: einfach bei der jeweils letzten Buchung dieser Serie den
  Haken "Wiederkehrend" entfernen - danach wird für diese Serie nichts mehr
  automatisch erzeugt.
- Automatisch erzeugte Buchungen sind in der Buchungsliste mit einem kleinen
  ⟲-Symbol markiert und lassen sich ganz normal bearbeiten oder löschen.

Das läuft einmalig beim Start (nicht im Hintergrund bei geschlossener App) und
holt dabei bis zu 24 fehlende Monate nach, falls die App länger nicht geöffnet
wurde.

## Suche & Filter in Buchungen

Im **Buchungen**-Tab gibt es unter dem Monats-/Personen-Filter ein Suchfeld,
das die Beschreibung case-insensitiv durchsucht, sowie ein Filter-Icon in der
AppBar (mit Punkt-Badge, sobald ein Filter aktiv ist) für:

- **Kategorie** (eine bestimmte Kategorie oder "Alle Kategorien")
- **Betrag von/bis** (vergleicht den Absolutbetrag, unabhängig von Einnahme/Ausgabe)

Alle Filter lassen sich kombinieren und wirken zusätzlich zum bereits gewählten
Monat/Personen-Filter; "Zurücksetzen" im Filter-Dialog setzt Kategorie und
Betragsbereich zurück. Andere Ansichten (Dashboard, Budgets, Jahresübersicht)
sind davon nicht betroffen - Suche/Filter gelten nur für die Buchungsliste
selbst.

## Konten-Verwaltung

Über das Verwaltungsmenü (⋮) im **Kategorien**-Tab → "Konten verwalten" lassen
sich beliebig viele Bankkonten anlegen (Name, Startsaldo, Farbe, optional einer
Person zugeordnet):

- Der angezeigte **Kontostand** ist keine eigene gespeicherte Zahl, sondern wird
  laufend aus Startsaldo + Summe aller diesem Konto zugeordneten Buchungen
  berechnet (`computeAccountBalance` in `lib/providers/account_providers.dart`).
- Jede Buchung (manuell, PDF-Import) kann optional einem Konto zugeordnet
  werden. Solange kein Konto angelegt ist, bleibt die Konto-Auswahl in den
  Formularen unsichtbar.
- **Umbuchung**: Über den zusätzlichen FAB "Umbuchung" (ab zwei Konten sichtbar)
  lässt sich Geld zwischen zwei eigenen Konten verschieben. Das erzeugt zwei
  verknüpfte Buchungen (gegenläufiger Betrag, gemeinsame `transferGroupId`,
  Kategorie "Umbuchung", Flag `isTransfer`) - eine je Konto, damit beide
  Kontostände stimmen.
- Umbuchungen zählen **nicht doppelt** als Ein-/Ausgabe: Dashboard,
  Jahresübersicht, Budget-Fortschritt (Monat + Jahr) und Optimierungsvorschläge
  blenden Buchungen mit `isTransfer = true` konsequent aus ihren Summen aus -
  sie verschieben nur Geld zwischen eigenen Konten, sind aber weder echtes
  Einkommen noch echte Ausgabe.
- Löscht man eine Umbuchung in der Buchungsliste, wird die verknüpfte
  Gegenbuchung auf dem anderen Konto automatisch mitgelöscht.
- Löscht man ein Konto selbst, bleiben dessen bisherige Buchungen erhalten,
  gelten danach aber als keinem Konto zugeordnet.

## Vermögensübersicht

Über das Verwaltungsmenü (⋮) im **Kategorien**-Tab → "Vermögensübersicht" lässt
sich das Netto-Vermögen über die reinen Bankkonten hinaus abbilden:

- Zusätzlich zu den Konten lassen sich beliebig viele **Vermögenswerte**
  (Investments/Depots, Immobilien, Sonstiges) und **Kredite/Schulden** manuell
  anlegen - jeweils mit Name, Art, aktuellem Wert, optionaler Person und Notiz.
- Der Wert wird **manuell gepflegt** (kein automatischer Kursabruf o. ä.) und
  bei Bedarf einfach durch Bearbeiten des Eintrags aktualisiert.
- Oben auf der Seite steht das **Netto-Vermögen**: Summe aller Kontostände
  plus aller Vermögenswerte, abzüglich aller Kredite/Schulden
  (`computeNetWorth` in `lib/providers/asset_providers.dart`) - reagiert live
  auf neue Buchungen, Kontostände und Personen-Filter.
- Konten werden zur Übersicht mit angezeigt, aber weiterhin ausschließlich über
  "Konten verwalten" bearbeitet - die Vermögensübersicht selbst verwaltet nur
  die zusätzlichen Positionen (Vermögenswerte/Kredite).

## Demo-Modus

Über das Verwaltungsmenü (⋮) im **Kategorien**-Tab → "Einstellungen" →
"Demodaten laden" lässt sich die App sofort ausprobieren, ohne selbst etwas
einzutragen:

- Lädt realistische Beispieldaten (`lib/services/demo_data_service.dart`):
  zwei Personen, zwei Konten, drei Monate an Buchungen (Miete, Nebenkosten,
  Streaming-Abos, Supermarkt, Tanken, Gehalt, ...), einen Firmenwagen, zwei
  Gehaltsabrechnungen, ein Investment-Depot und einen Kredit - abgestimmt
  darauf, dass dabei auch die Optimierungsvorschläge (doppelte Streaming-Abos,
  eine Ausgabenspitze) und eine Umbuchung zwischen den beiden Demo-Konten
  sichtbar werden.
- Alle erzeugten Einträge tragen eine `demo_`-ID und sind im Namen mit
  "(Demo)" gekennzeichnet. Erneutes Laden überschreibt dieselben Einträge
  (kein Duplizieren); "Demodaten entfernen" löscht ausschließlich Einträge
  mit `demo_`-ID wieder - eigene Daten bleiben davon komplett unberührt.
- Bewusst **ohne** Budgets: Ein Standard-Budget teilt sich die ID mit seiner
  Kategorie, ein Demo-Budget könnte also ein bereits von dir gesetztes Budget
  überschreiben - dieses eine Risiko wird vermieden, indem der Demo-Modus
  keine Budgets anlegt.

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

## Mögliche Erweiterungen

- Echtes Hintergrund-Push (statt nur lokaler In-App-Erinnerungen bei
  geöffneter App) sowie Windows-Unterstützung für Erinnerungen.
- CSV-Import als zuverlässigere Alternative/Ergänzung zum PDF-Import.
