# Finance Analyzer - Projekt-Dokumentation

Dokumentation für Entwickler, die mit diesem Flutter-Projekt arbeiten.

## 🎯 Projekt-Überblick

**Finance Analyzer** ist eine Cross-Platform-Finanz-Management-App, geschrieben in Flutter/Dart. Die App ermöglicht:

- 📊 Kontoauszüge und Gehaltsabrechnungen als PDF importieren
- 💰 Buchungen manuell erfassen und kategorisieren
- 📈 Monatliche und jährliche Finanzübersichten anzeigen
- 🎯 Budgets und Sparziele verwalten
- 🔄 Automatische wiederkehrende Buchungen
- 📱 Mehrere Bankkonten unterstützen
- 💼 Vermögensübersicht und Firmenwagen-Verwaltung

**Zielplattformen:** Android, iOS, macOS, Windows, Linux, Web

## 📁 Projektstruktur

```
lib/
  ├── models/          # Datenmodelle (Category, Transaction, SalarySlip, etc.)
  │   └── *_model.dart + Hive TypeAdapter + toJson/fromJson
  │
  ├── data/            # Hive-Konfiguration und Seed-Daten
  │   ├── hive_setup.dart
  │   └── default_categories.dart
  │
  ├── repositories/    # CRUD-Operationen auf Hive-Boxen
  │   ├── transaction_repository.dart
  │   ├── category_repository.dart
  │   ├── salary_slip_repository.dart
  │   └── ...
  │
  ├── providers/       # Riverpod-Provider und State Management
  │   ├── month_filter_provider.dart
  │   ├── person_filter_provider.dart
  │   ├── transaction_provider.dart
  │   ├── insights_provider.dart
  │   └── ...
  │
  ├── services/        # Business-Logik und externe Services
  │   ├── pdf_import_service.dart      # PDF-Parser für Kontoauszüge
  │   ├── salary_parser_service.dart   # Gehaltsabrechnung-Parser
  │   ├── categorization_service.dart  # Auto-Kategorisierung
  │   ├── optimization_service.dart    # Optimierungsvorschläge
  │   ├── backup_service.dart          # Backup/Export/Import
  │   └── file_service.dart            # Plattformspezifisches Datei-Handling
  │
  ├── screens/         # Haupt-UI-Screens
  │   ├── home_screen.dart
  │   ├── transactions_screen.dart
  │   ├── import_screen.dart
  │   ├── salary_screen.dart
  │   ├── budget_screen.dart
  │   ├── settings_screen.dart
  │   └── ...
  │
  ├── widgets/         # Wiederverwendbare UI-Komponenten
  │   ├── charts/               # Chart-Widgets
  │   ├── common/               # Allgemeine Widgets
  │   ├── filters/              # Filter-UI
  │   ├── cards/                # Summary-Cards
  │   └── ...
  │
  └── main.dart        # App-Einstiegspunkt

android/              # Android-spezifischer Code
ios/                  # iOS-spezifischer Code
macos/                # macOS-spezifischer Code
windows/              # Windows-spezifischer Code
linux/                # Linux-spezifischer Code
web/                  # Web-spezifischer Code

test/                 # Unit- und Widget-Tests
```

## 🚀 Schnellstart

### Installation
```bash
# Repository klonen
git clone https://github.com/tobiaskgr/remote.git
cd remote
git checkout claude/claw-code-installation-setup-mlvhqc

# Setup-Skript ausführen
./setup.sh  # macOS/Linux
# oder
.\setup.ps1  # Windows
```

### Erste Schritte
```bash
# App auf Gerät/Emulator starten
flutter run -d <device>

# Verfügbare Geräte anzeigen
flutter devices
```

### Tests
```bash
# Unit-Tests
flutter test

# Spezifische Test-Datei
flutter test test/models/transaction_model_test.dart

# Coverage Report
flutter test --coverage
```

## 🔧 Wichtige Dependencies

| Package | Zweck |
|---------|--------|
| `flutter_riverpod` | State Management |
| `hive` + `hive_flutter` | Persistente lokale Speicherung |
| `syncfusion_flutter_pdf` | PDF-Textextraktion |
| `fl_chart` | Diagramme und Visualisierungen |
| `flutter_local_notifications` | Lokale Push-Benachrichtigungen |
| `file_picker` | Datei-Auswahl-Dialog |
| `path_provider` | Plattformspezifische Pfade |
| `intl` | Internationalisierung |

## 🏗️ Architektur-Highlights

### State Management (Riverpod)
- **Reaktive Provider:** Automatische UI-Updates bei Datenänderungen
- **Family-Provider:** Parametrisierte Provider (z.B. Filter)
- **AsyncValue:** Asynchrone Operationen mit Loading/Error-States

Beispiel:
```dart
final transactionsProvider = FutureProvider.autoDispose((ref) async {
  return await transactionRepository.getAllTransactions();
});
```

### Persistenz (Hive)
- Typsicher durch Dart
- Keine Server/Backend nötig
- Auch im Web (IndexedDB)
- Schnelle Abfragen durch lokalen In-Memory-Index

Modelldefinition:
```dart
@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double amount;
  // ...
}
```

### PDF-Import
Heuristische Regex-basierte Erkennung für deutsche Kontoauszüge:
- Datum-Pattern: `TT.MM.JJJJ`
- Betrag-Pattern: deutsches Komma-Format mit `S`/`H` oder `+`/`-`
- Review-Screen für manuelle Korrektur vor dem Speichern

## 📝 Code-Richtlinien

### Naming Conventions
- **Classes:** PascalCase (`TransactionScreen`, `TransactionRepository`)
- **Functions/Methods:** camelCase (`getTransactions()`, `calculateMonthlySum()`)
- **Variables:** camelCase (`totalAmount`, `isLoading`)
- **Constants:** camelCase, optional mit `k` Prefix (`kDefaultPadding = 16.0`)
- **Private:** mit `_` Prefix (`_calculateSum()`, `_repository`)

### Struktur für neue Features
1. **Model definieren** → `lib/models/feature_model.dart`
2. **Repository** → `lib/repositories/feature_repository.dart`
3. **Provider** → `lib/providers/feature_provider.dart`
4. **UI-Widgets** → `lib/screens/feature_screen.dart`
5. **Tests** → `test/feature_test.dart`

### Best Practices
- ✅ Immutable Models (mit `@freezed` oder manuell)
- ✅ Provider-Auflösung in `finally`-Blöcken
- ✅ Error-Handling in AsyncValue
- ✅ Tests für Business-Logik (Services, Repositories)
- ❌ Keine globalen Variablen
- ❌ Kein direkter Hive-Zugriff außerhalb von Repositories

## 🔄 Build-Prozess

### Debug-Build
```bash
flutter run -d <device>
```

### Release-Build pro Plattform
```bash
flutter build apk --release      # Android APK
flutter build appbundle          # Android Play Store AAB
flutter build ios --release      # iOS
flutter build macos --release    # macOS
flutter build windows --release  # Windows
flutter build linux --release    # Linux
flutter build web --release      # Web
```

Detaillierte Anleitung: siehe `INSTALLATION.md`

## 🧪 Testing

### Unit-Tests
```dart
test('TransactionRepository saves transaction', () {
  final repository = TransactionRepository();
  final transaction = Transaction(...);
  repository.addTransaction(transaction);
  expect(repository.getAll(), contains(transaction));
});
```

### Widget-Tests
```dart
testWidgets('TransactionCard displays amount', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TransactionCard(transaction: mockTransaction),
    ),
  );
  expect(find.text('€100,00'), findsOneWidget);
});
```

### Integration-Tests
```bash
# Emulator/Device starten
flutter drive --target=test_driver/app.dart
```

## 🔒 Sicherheit & Datenschutz

- ✅ Alle Daten lokal auf dem Gerät gespeichert
- ✅ Kein Backend/Server nötig → maximale Privatsphäre
- ✅ Kein Netzwerk-Zugriff erforderlich
- ✅ Backup/Export als JSON (lokal speicherbar)
- ⚠️ PDF-Parser verarbeitet Daten lokal (Syncfusion Community-Lizenz)

## 🌐 Lokalisierung

Momentan: Deutsch (de)

Zukünftige Unterstützung:
```dart
// In pubspec.yaml
intl: ^0.20.2

// In lib/main.dart
localizationsDelegates: [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: [
  const Locale('de'),
  const Locale('en'),
],
```

## 🐛 Debugging

### Häufige Probleme

**1. Hive TypeAdapter-Fehler**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter clean
flutter pub get
```

**2. PDF-Import funktioniert nicht**
- Überprüfe `lib/services/pdf_import_service.dart` Regex
- Review-Screen muss Betrag-Erkennung validieren

**3. Performance-Problem**
- Riverpod DevTools einbinden
- `flutter run --profile` verwenden
- Hive-Abfragen optimieren (Index-Nutzung)

## 🤝 Beitragen

1. **Feature-Branch erstellen:**
   ```bash
   git checkout -b feature/deine-feature
   ```

2. **Tests schreiben** (mindestens für Business-Logik)

3. **Code-Stil prüfen:**
   ```bash
   flutter analyze
   flutter format .
   ```

4. **Commit & Push:**
   ```bash
   git add .
   git commit -m "feat: Beschreibung deiner Änderung"
   git push origin feature/deine-feature
   ```

5. **Pull Request öffnen** mit Beschreibung

## 📚 Weitere Ressourcen

- **Flutter Docs:** https://flutter.dev/docs
- **Riverpod Guide:** https://riverpod.dev
- **Hive Documentation:** https://docs.hivedb.dev
- **Material Design:** https://material.io/design

## 📞 Fragen & Support

Bei Fragen zum Projekt:
1. Prüfe die bestehende Dokumentation (`INSTALLATION.md`, dieses File)
2. Schau die Beispiele in `lib/` an
3. Erstelle ein GitHub Issue mit Details

---

**Letzte Aktualisierung:** 31.07.2026
**Wartung:** Team
