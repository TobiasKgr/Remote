# Installationsanleitung - Finance Analyzer

Umfassende Anleitung zur Einrichtung und zum Build des Finance Analyzer für alle Plattformen (Android, iOS, macOS, Windows, Linux, Web).

## Voraussetzungen (alle Plattformen)

### Erforderliche Software
- **Flutter SDK** (3.12.2 oder höher): [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (wird mit Flutter installiert)
- **Git**
- **IDE** (empfohlen: VS Code oder Android Studio/IntelliJ)

### Installation Flutter SDK

```bash
# Flutter herunterladen und installieren
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$(pwd)/flutter/bin"

# Installation verifizieren
flutter --version
flutter doctor
```

---

## Platform-spezifische Voraussetzungen

### Android

**Erforderlich:**
- Android SDK (API Level 21+, Target API Level 34+)
- Android Studio (enthält SDK und Emulator)
- JDK 11+

**Installation auf macOS/Linux:**
```bash
# Android Studio herunterladen und installieren
# Dann in Flutter den Android SDK konfigurieren:
flutter config --android-sdk /path/to/android-sdk
flutter config --android-studio-path /path/to/android-studio

# Lizenzen akzeptieren
flutter doctor --android-licenses
```

**Installation auf Windows:**
```powershell
# Admin-Terminal öffnen
flutter config --android-sdk "C:\Android\sdk"
flutter config --android-studio-path "C:\Program Files\Android\Android Studio"
flutter doctor --android-licenses
```

### iOS

**Erforderlich (nur macOS):**
- macOS 12.0+
- Xcode 14.0+
- CocoaPods

**Installation:**
```bash
# Xcode Command Line Tools
xcode-select --install

# CocoaPods (falls nicht vorhanden)
sudo gem install cocoapods

# iOS Deployment Target überprüfen
cd ios
pod repo update
cd ..

# Flutter überprüfen
flutter doctor -v
```

### macOS Desktop

**Erforderlich:**
- macOS 10.15+
- Xcode 12.0+ oder Command Line Tools

**Installation:**
```bash
# Command Line Tools (minimal)
xcode-select --install
```

### Windows Desktop

**Erforderlich:**
- Windows 10 or höher
- Visual Studio 2019+ oder Build Tools

**Installation:**
```powershell
# Visual Studio Build Tools (minimal)
# Download von: https://visualstudio.microsoft.com/downloads/
# Mindestens "Desktop development with C++" wählen
```

### Linux Desktop

**Erforderlich (Ubuntu/Debian):**
```bash
sudo apt-get install \
  clang cmake git ninja-build pkg-config \
  libblkid-dev libgtk-3-dev liblzma-dev libsecret-1-dev \
  libsystemd-dev
```

**Erforderlich (Fedora/RHEL):**
```bash
sudo dnf install \
  clang cmake git ninja-build pkg-config \
  glibc-devel gcc libstdc++-devel gtk3-devel \
  openssl-devel
```

---

## Projekt-Setup

### 1. Repository klonen
```bash
git clone https://github.com/tobiaskgr/remote.git
cd remote
git checkout claude/claw-code-installation-setup-mlvhqc
```

### 2. Flutter-Abhängigkeiten installieren
```bash
flutter clean
flutter pub get
```

### 3. Code-Generierung (falls erforderlich)
```bash
# Hive Type Adapter generieren
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Setup-Status überprüfen
```bash
flutter doctor
# Alle Häkchen sollten grün sein für die Plattformen, auf die Sie abzielen
```

---

## Build & Run für jede Plattform

### Android

**Voraussetzungen:**
- Android Device oder Emulator verbunden/laufend
- `flutter devices` sollte das Device anzeigen

**Debug-Build:**
```bash
flutter run -d android
```

**Release-Build (APK):**
```bash
flutter build apk --release
# Ausgabe: build/app/outputs/flutter-apk/app-release.apk
```

**Release-Build (AAB für Play Store):**
```bash
flutter build appbundle --release
# Ausgabe: build/app/outputs/bundle/release/app-release.aab
```

**Signieren (für Play Store):**
```bash
# Keystore erstellen (einmalig)
keytool -genkey -v -keystore ~/android_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias finance_analyzer_key

# In android/key.properties eintragen
echo "storeFile=/path/to/android_key.jks" > android/key.properties
echo "storePassword=PASSWORD" >> android/key.properties
echo "keyPassword=PASSWORD" >> android/key.properties
echo "keyAlias=finance_analyzer_key" >> android/key.properties
```

### iOS

**Voraussetzungen:**
- macOS mit Xcode
- Apple Developer Account (für echte Geräte)

**Debug-Build (Simulator):**
```bash
flutter run -d ios
```

**Release-Build (Simulator):**
```bash
flutter build ios --release
```

**Release-Build (physisches Device):**
```bash
# Provisioning Profile einrichten in Xcode
open ios/Runner.xcworkspace

# Dann in Runner-Projekt:
# 1. Signing & Capabilities konfigurieren
# 2. Bundle ID einstellen
# 3. Team ID eintragen

# Build via Flutter:
flutter build ios --release
# Ausgabe: build/ios/iphoneos/Runner.app
```

**Für App Store (.ipa):**
```bash
flutter build ios --release
# Dann in Xcode archivieren und hochladen
```

### macOS Desktop

**Debug-Build:**
```bash
flutter run -d macos
```

**Release-Build (.dmg):**
```bash
flutter build macos --release
# Ausgabe: build/macos/Build/Products/Release/finance_analyzer.app
```

**Paketieren als .dmg:**
```bash
# Manuell in Finder oder mit create-dmg:
brew install create-dmg
create-dmg \
  --volname "Finance Analyzer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "finance_analyzer.app" 200 190 \
  --hide-extension "finance_analyzer.app" \
  --app-drop-link 600 190 \
  "finance_analyzer.dmg" "build/macos/Build/Products/Release/"
```

### Windows Desktop

**Debug-Build:**
```bash
flutter run -d windows
```

**Release-Build (.exe):**
```bash
flutter build windows --release
# Ausgabe: build/windows/x64/runner/Release/finance_analyzer.exe
```

**MSIX-Installer (für Windows App Store):**
```bash
flutter pub get
flutter build windows --release
# MSIX Konfiguration in pubspec.yaml oder manual via Tool
```

### Linux Desktop

**Debug-Build:**
```bash
flutter run -d linux
```

**Release-Build:**
```bash
flutter build linux --release
# Ausgabe: build/linux/x64/release/bundle/finance_analyzer
```

**AppImage (portabel):**
```bash
# AppImage Builder installieren
pip install appimage-builder

# AppImage erstellen (im Projektverzeichnis)
appimage-builder --recipe AppImageBuilder.yml
```

### Web

**Debug-Build:**
```bash
flutter run -d chrome
# oder: firefox, edge, safari
```

**Release-Build:**
```bash
flutter build web --release
# Ausgabe: build/web/
# Hochladen des build/web/ Verzeichnis auf Webserver
```

---

## Automatisiertes Setup-Skript

Für Linux/macOS:

```bash
#!/bin/bash
# setup.sh - Automatisiertes Projekt-Setup

set -e

echo "🚀 Finance Analyzer - Setup-Skript"
echo "===================================="

# 1. Flutter überprüfen
echo "✓ Prüfe Flutter-Installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter nicht gefunden. Bitte installieren: https://flutter.dev/docs/get-started/install"
    exit 1
fi
flutter doctor -v

# 2. Abhängigkeiten
echo "✓ Lade Flutter-Abhängigkeiten..."
flutter clean
flutter pub get

# 3. Code-Generierung
echo "✓ Generiere Hive Type Adapter..."
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Basis-Setup abgeschlossen
echo ""
echo "✅ Setup abgeschlossen!"
echo ""
echo "Nächste Schritte:"
echo "  • flutter doctor         (Status überprüfen)"
echo "  • flutter run -d <device> (App starten)"
echo "  • flutter build <platform> (Für Produktion bauen)"
```

Für Windows:

```powershell
# setup.ps1 - Automatisiertes Projekt-Setup

Write-Host "🚀 Finance Analyzer - Setup-Skript" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# 1. Flutter überprüfen
Write-Host "✓ Prüfe Flutter-Installation..." -ForegroundColor Yellow
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter nicht gefunden. Bitte installieren: https://flutter.dev/docs/get-started/install" -ForegroundColor Red
    exit 1
}
flutter doctor -v

# 2. Abhängigkeiten
Write-Host "✓ Lade Flutter-Abhängigkeiten..." -ForegroundColor Yellow
flutter clean
flutter pub get

# 3. Code-Generierung
Write-Host "✓ Generiere Hive Type Adapter..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

Write-Host ""
Write-Host "✅ Setup abgeschlossen!" -ForegroundColor Green
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Cyan
Write-Host "  • flutter doctor" -ForegroundColor Gray
Write-Host "  • flutter run -d <device>" -ForegroundColor Gray
Write-Host "  • flutter build <platform>" -ForegroundColor Gray
```

---

## Troubleshooting

### Flutter Doctor zeigt Fehler

```bash
# Vollständige Diagnose
flutter doctor -v

# Häufige Lösungen:
flutter clean
flutter pub get
flutter pub upgrade
```

### Android-Build schlägt fehl

```bash
# Gradle Cache löschen
rm -rf ~/.gradle/caches/

# Neu bauen
flutter clean
flutter pub get
flutter build apk --verbose
```

### iOS CocoaPods-Fehler

```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod repo update
pod install
cd ..
flutter clean
flutter pub get
```

### Build Runner Fehler

```bash
# Build Runner Cache löschen
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Environment-Variablen

Optional für erweiterte Konfiguration:

```bash
# macOS/Linux
export FLUTTER_CHANNEL=stable
export FLUTTER_ROOT=/path/to/flutter
export PATH="$PATH:$FLUTTER_ROOT/bin"

# Windows (PowerShell)
$env:FLUTTER_CHANNEL = "stable"
$env:FLUTTER_ROOT = "C:\path\to\flutter"
```

---

## Nächste Schritte nach Setup

1. **Lokale Änderungen testen:** `flutter run -d <device>`
2. **Tests ausführen:** `flutter test`
3. **Code-Style prüfen:** `flutter analyze`
4. **Distribution vorbereiten:** Siehe plattformspezifische Guides oben
5. **CI/CD einrichten:** GitHub Actions / Fastlane (siehe separate Dokumentation)

---

## Hilfreiche Ressourcen

- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Android Build Guide](https://flutter.dev/docs/deployment/android)
- [iOS Build Guide](https://flutter.dev/docs/deployment/ios)
- [Desktop Build Guides](https://flutter.dev/docs/deployment/flavors)
