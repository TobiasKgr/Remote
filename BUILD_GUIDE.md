# Build & Distribution Guide - Finance Analyzer

Detaillierte Anleitung zum Bauen und Verteilen der Finance Analyzer App für alle Plattformen.

## 📱 Android

### Vorbereitung

1. **Keystore für Signierung erstellen** (einmalig):
```bash
keytool -genkey -v -keystore ~/android_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias finance_analyzer_key
# Beim Prompt Passwort eingeben
```

2. **Keystore-Daten speichern** in `android/key.properties`:
```properties
storeFile=/home/username/android_key.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=finance_analyzer_key
```

3. **Berechtigungen überprüfen** in `android/app/src/main/AndroidManifest.xml`

### Release-Build

#### APK (für direkte Installation)
```bash
flutter build apk --release --verbose
# Ausgabe: build/app/outputs/flutter-apk/app-release.apk
```

**Größe optimieren:**
```bash
flutter build apk --release --split-per-abi
# Erzeugt app-armeabi-v7a-release.apk, app-arm64-v8a-release.apk, etc.
```

#### AAB (für Google Play Store)
```bash
flutter build appbundle --release --verbose
# Ausgabe: build/app/outputs/bundle/release/app-release.aab
```

### Google Play Store Veröffentlichung

1. **Google Play Developer Konto:** https://play.google.com/console
2. **App-Setup in Play Console:**
   - App-Name, Beschreibung, Kategorie
   - Berechtigungen überprüfen
   - Content-Rating ausfüllen
   - Preismodell wählen

3. **AAB hochladen:**
   - Play Console → App-Releases → Produktion
   - `app-release.aab` hochladen
   - Release-Notizen eingeben
   - Bestätigung und Veröffentlichung

4. **Nach Veröffentlichung:**
   - Google Play Protect-Scan abwarten (~2-4h)
   - Rollout stufenweise (z.B. 5% → 25% → 100%)

### Direkter APK-Versand

```bash
# APK signieren (falls nicht automatisch geschehen)
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/android_key.jks \
  build/app/outputs/flutter-apk/app-release.apk \
  finance_analyzer_key

# APK zipen für Verteilung
zip finance_analyzer_release.zip build/app/outputs/flutter-apk/app-release.apk
```

---

## 🍎 iOS

### Voraussetzungen (nur macOS)

```bash
# Xcode Command Line Tools
xcode-select --install

# CocoaPods aktualisieren
sudo gem install cocoapods
pod repo update
```

### Vorbereitung

1. **Apple Developer Account:** https://developer.apple.com
2. **App-ID registrieren:**
   - Identifiers → Bundle ID (z.B. `com.tobias.financeanalyzer`)
   - Capabilities aktivieren (falls nötig)

3. **Provisioning Profiles:**
   - Development Profile für Testing
   - Distribution Profile für App Store

4. **Xcode konfigurieren:**
```bash
open ios/Runner.xcworkspace
# Im Xcode:
# 1. Runner-Projekt wählen
# 2. Signing & Capabilities
# 3. Team ID eintragen
# 4. Bundle ID anpassen
```

### Release-Build

#### Für TestFlight/App Store
```bash
flutter build ios --release --verbose
# Generiert: build/ios/iphoneos/Runner.app
```

#### Archive (für Xcode)
```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build \
  -archivePath build/Runner.xcarchive archive
cd ..
```

### App Store Veröffentlichung

1. **App Store Connect:** https://appstoreconnect.apple.com
2. **Neue App erstellen:**
   - App-Name, Kategorie
   - Datenschutzerklärung eintragen
   - Screenshots hochladen (5 pro Gerätegröße)
   - Beschreibung, Keywords, Support-URL

3. **Build hochladen** via Xcode:
```bash
# Im Xcode (build/Runner.xcarchive):
# Organizer → Runner.xcarchive → Distribute App
# App Store → Upload
```

   Oder via Command Line:
```bash
xcrun altool --upload-app \
  --type ios \
  --file "path/to/Runner.ipa" \
  --username your-apple-id@example.com \
  --password app-specific-password
```

4. **TestFlight-Testing:**
   - Mindestens 1 interner Tester
   - Dann externe Tester einladen
   - Feedback-Sammlung vor App Store-Release

### Manueller Ad-Hoc-Vertrieb

```bash
# IPA exportieren
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/
cd ..
# build/Runner.ipa → Per Email/Cloud verteilen
```

---

## 🖥️ macOS Desktop

### Vorbereitung

```bash
# Xcode überprüfen
xcode-select --version

# Code Signing Certificate vorbereiten (für Verteilung)
# Notizen: 3rd Party Mac Developer
```

### Release-Build

```bash
flutter build macos --release --verbose
# Ausgabe: build/macos/Build/Products/Release/finance_analyzer.app
```

### Distribution

#### Direkter .app Versand
```bash
# Zip für Verteilung
cd build/macos/Build/Products/Release/
zip -r finance_analyzer.app.zip finance_analyzer.app
# Hochladen und verteilen
```

#### Mac App Store
```bash
# Sandboxing und Code Signing konfigurieren
# Dann: Product → Prepare for Submission in Xcode

# Oder per Command Line:
xcrun altool --upload-app \
  --type osx \
  --file "path/to/finance_analyzer.app" \
  --username your-apple-id@example.com \
  --password app-specific-password
```

#### DMG-Installer
```bash
# Homebrew: create-dmg
brew install create-dmg

# DMG erstellen
create-dmg \
  --volname "Finance Analyzer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "finance_analyzer.app" 200 190 \
  --hide-extension "finance_analyzer.app" \
  --app-drop-link 600 190 \
  "finance_analyzer.dmg" "build/macos/Build/Products/Release/"

# Code Signing (optional, für Vertrieb)
codesign --deep --force --verify --verbose --sign "-" \
  build/macos/Build/Products/Release/finance_analyzer.app

# Notarization für macOS 10.15+
xcrun altool --notarize-app \
  --file finance_analyzer.dmg \
  --primary-bundle-id com.tobias.financeanalyzer \
  --username your-apple-id@example.com \
  --password app-specific-password
```

---

## 🪟 Windows Desktop

### Vorbereitung

```bash
# Visual Studio Build Tools überprüfen
# Oder: Visual Studio 2019+ installieren
```

### Release-Build

```bash
flutter build windows --release --verbose
# Ausgabe: build/windows/x64/runner/Release/finance_analyzer.exe
```

### Distribution

#### Direkter .exe Versand
```bash
# ZIP für Verteilung
cd build/windows/x64/runner/Release/
Compress-Archive -Path finance_analyzer.exe, assets, data -DestinationPath finance_analyzer.zip
# Hochladen und verteilen
```

#### MSIX-Installer (Windows App Store)
```bash
# MSIX Konfiguration in pubspec.yaml:
msix_config:
  display_name: Finance Analyzer
  publisher_display_name: Your Company
  identity_name: YourCompany.FinanceAnalyzer
  certificate_path: path/to/certificate.pfx
  certificate_password: your_password
  languages: de-de

# Build
flutter pub get
flutter build windows --release
# Dann: msix-package-tool oder visual studio
```

#### Standalone-Installer (.msi)
```bash
# Inno Setup verwenden (optional)
# Download: https://jrsoftware.org/isinfo.php
# Script erstellen für Installer-Paketierung

# Oder: WiX Toolset (Microsoft)
# Download: https://github.com/wixtoolset/wix3/releases
```

---

## 🐧 Linux Desktop

### Vorbereitung

**Ubuntu/Debian:**
```bash
sudo apt-get install \
  build-essential cmake pkg-config ninja-build \
  libgtk-3-dev liblzma-dev liblz4-dev libsecret-1-dev
```

**Fedora/RHEL:**
```bash
sudo dnf install cmake pkg-config ninja-build \
  gcc-c++ libstdc++-devel gtk3-devel liblzma-devel
```

### Release-Build

```bash
flutter build linux --release --verbose
# Ausgabe: build/linux/x64/release/bundle/finance_analyzer
```

### Distribution

#### AppImage (portabel, Linux-übergreifend)
```bash
# AppImage Builder installieren
pip install appimage-builder

# AppImage erstellen
appimage-builder --recipe AppImageBuilder.yml

# AppImage Runtime herunterladbar
# https://github.com/AppImage/AppImageKit/releases

# Beispiel AppImageBuilder.yml:
```
```yaml
version: 1
AppDir:
  path: build/linux/x64/release/bundle
  app_info:
    id: com.tobias.financeanalyzer
    name: Finance Analyzer
    icon: assets/icon.png
    version: 0.1.0
    exec: finance_analyzer
AppImage:
  file_name: Finance_Analyzer-0.1.0-x86_64.AppImage
```

#### .deb Paket (Debian/Ubuntu)
```bash
# Kontrollskript erstellen: DEBIAN/control
mkdir -p debian/DEBIAN
cat > debian/DEBIAN/control << EOF
Package: finance-analyzer
Version: 0.1.0
Architecture: amd64
Maintainer: Your Name <email@example.com>
Description: Cross-platform finance management app
Homepage: https://github.com/tobiaskgr/remote
EOF

# Binary kopieren
mkdir -p debian/usr/bin
cp build/linux/x64/release/bundle/finance_analyzer debian/usr/bin/

# .deb erstellen
dpkg-deb --build debian finance-analyzer_0.1.0_amd64.deb
```

#### .rpm Paket (Fedora/RHEL)
```bash
# RPM Specfile erstellen
cat > finance-analyzer.spec << EOF
Name:           finance-analyzer
Version:        0.1.0
Release:        1%{?dist}
Summary:        Cross-platform finance management app
License:        MIT

%description
Finance Analyzer - PDF import, categorization, and financial insights

%install
mkdir -p %{buildroot}/usr/bin
cp build/linux/x64/release/bundle/finance_analyzer %{buildroot}/usr/bin/

%files
/usr/bin/finance_analyzer
EOF

# RPM bauen
rpmbuild -bb finance-analyzer.spec
```

---

## 🌐 Web

### Release-Build

```bash
flutter build web --release --verbose
# Ausgabe: build/web/
```

### Hosting-Optionen

#### Firebase Hosting
```bash
# Firebase CLI installieren
npm install -g firebase-tools
firebase login

# Firebase Projekt initialisieren
firebase init

# Deploy
firebase deploy --only hosting
```

#### GitHub Pages
```bash
# Repository: https://github.com/tobiaskgr/remote
# In den Settings:
# - Pages → Source → Branch: main
# - Deploy from: /docs Folder

# Build in docs/ Verzeichnis
flutter build web --release --output=docs/

# Commit und Push
git add docs/
git commit -m "build: web release"
git push
```

#### Selbst gehosteter Server
```bash
# Dateien auf Server kopieren
scp -r build/web/* user@server:/var/www/html/finance-analyzer/

# Oder mit rsync
rsync -avz build/web/ user@server:/var/www/html/finance-analyzer/
```

---

## 🔄 Continuous Delivery (CI/CD)

### GitHub Actions Beispiel

`.github/workflows/build.yml`:
```yaml
name: Build & Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    strategy:
      matrix:
        platform: [android, ios, windows, linux, web]
    runs-on: ${{ matrix.platform == 'ios' && 'macos-latest' || 'ubuntu-latest' }}
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.12.2'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build ${{ matrix.platform }}
        run: flutter build ${{ matrix.platform }} --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v2
        with:
          name: ${{ matrix.platform }}-release
          path: build/${{ matrix.platform }}/
```

---

## 📦 Versionierung

### Versionsnummer aktualisieren

1. **pubspec.yaml:**
```yaml
version: 0.1.0+1
#         │      └─ Build Number (für App Stores)
#         └─────── Version (Semantic Versioning)
```

2. **Android:**
```gradle
// android/app/build.gradle.kts
android {
    defaultConfig {
        versionCode = 1         // +1 für jeden Release
        versionName = "0.1.0"   // Semver
    }
}
```

3. **iOS:**
```
// ios/Runner/Info.plist
CFBundleShortVersionString: 0.1.0
CFBundleVersion: 1
```

### Git Tags
```bash
git tag -a v0.1.0 -m "Release 0.1.0"
git push origin v0.1.0
```

---

## 🔍 Testing vor Release

```bash
# Unit Tests
flutter test

# Widget Tests
flutter test test/widgets/

# Integration Tests
flutter drive --target=test_driver/app.dart

# Code Analysis
flutter analyze

# Code Format
flutter format .

# Performance Testing
flutter run --profile

# Coverage
flutter test --coverage
lcov --list coverage/lcov.info
```

---

## 📋 Checkliste vor Release

- [ ] Tests durchgeführt und bestanden
- [ ] Version in pubspec.yaml aktualisiert
- [ ] CHANGELOG aktualisiert
- [ ] Code-Analyse erfolgreich (`flutter analyze`)
- [ ] Performance-Test durchgeführt
- [ ] Alle Plattformen getestet (Debug-Build)
- [ ] Release-Build erfolgreich generiert
- [ ] Signierung/Zertifikate überprüft
- [ ] Screenshots aktualisiert (für App Stores)
- [ ] Store-Einträge überprüft (Beschreibung, Keywords)
- [ ] Git Tag erstellt (`git tag v0.1.0`)
- [ ] Backup/Rollback-Plan vorhanden

---

## 🚨 Troubleshooting

### Build schlägt fehl

```bash
# Vollständige Diagnose
flutter clean
flutter pub get
flutter doctor -v

# Verbose Output
flutter build <platform> --verbose

# Pods/Dependencies Cache löschen
flutter clean
rm -rf ios/Pods ios/Podfile.lock  # iOS
rm -rf ~/.gradle                   # Android
flutter pub get
```

### Signierungs-Fehler

```bash
# Android
rm -f android/key.properties
# Keystore neu erstellen und Pfade aktualisieren

# iOS
# Xcode → Runner → Signing & Capabilities
# Team ID und Bundle ID überprüfen

# macOS
security find-identity -v -p codesigning
```

### Storage-Probleme

```bash
# Build-Artefakte löschen
flutter clean
rm -rf build/

# Caches löschen
flutter clean
cd ios && rm -rf Pods Podfile.lock && cd ..
rm -rf ~/.gradle
```

---

## 📞 Support & Ressourcen

- **Flutter Build Guides:** https://flutter.dev/docs/deployment
- **Play Console Docs:** https://support.google.com/googleplay/android-developer
- **App Store Docs:** https://developer.apple.com/app-store/submissions/
- **GitHub Actions:** https://github.com/features/actions

---

**Letzte Aktualisierung:** 31.07.2026
**Wartung:** Team
