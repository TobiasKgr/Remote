# setup.ps1 - Automatisiertes Projekt-Setup für Finance Analyzer
# Verwendung: .\setup.ps1 [-SkipDoctor] [-NoBuildRunner] [-Platform <platform>]

param(
    [switch]$SkipDoctor,
    [switch]$NoBuildRunner,
    [string]$Platform = ""
)

# Fehlerbehandlung
$ErrorActionPreference = "Stop"

# Header
Write-Host ""
Write-Host "🚀 Finance Analyzer - Setup-Skript" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Flutter Installation überprüfen
Write-Host "✓ Prüfe Flutter-Installation..." -ForegroundColor Yellow
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "❌ Flutter nicht gefunden!" -ForegroundColor Red
    Write-Host "Bitte installieren: https://flutter.dev/docs/get-started/install" -ForegroundColor Red
    exit 1
}

$flutterVersion = flutter --version | Select-Object -First 1
Write-Host "  $flutterVersion" -ForegroundColor Green

# 2. Flutter Doctor (optional)
if (-not $SkipDoctor) {
    Write-Host ""
    Write-Host "✓ Führe 'flutter doctor' aus..." -ForegroundColor Yellow
    flutter doctor -v
}

# 3. Flutter Clean
Write-Host ""
Write-Host "✓ Räume auf (flutter clean)..." -ForegroundColor Yellow
flutter clean

# 4. Abhängigkeiten abrufen
Write-Host "✓ Lade Flutter-Abhängigkeiten..." -ForegroundColor Yellow
flutter pub get

# 5. Build Runner (optional)
if (-not $NoBuildRunner) {
    Write-Host "✓ Generiere Code (build_runner)..." -ForegroundColor Yellow
    flutter pub run build_runner build --delete-conflicting-outputs
}

# 6. Plattform-spezifisches Setup
if ($Platform) {
    Write-Host ""
    Write-Host "✓ Führe plattformspezifisches Setup aus: $Platform" -ForegroundColor Yellow

    switch ($Platform.ToLower()) {
        "android" {
            Write-Host "  Überprüfe Android-Umgebung..." -ForegroundColor Gray
            $adb = Get-Command adb -ErrorAction SilentlyContinue
            if (-not $adb) {
                Write-Host "  ⚠️  adb nicht gefunden - Android SDK möglicherweise nicht konfiguriert" -ForegroundColor Yellow
            } else {
                adb devices
            }
        }
        "ios" {
            Write-Host "  ⚠️  iOS nur auf macOS verfügbar" -ForegroundColor Yellow
        }
        "macos" {
            Write-Host "  ⚠️  macOS nur auf macOS verfügbar" -ForegroundColor Yellow
        }
        "linux" {
            Write-Host "  ⚠️  Linux nur auf Linux verfügbar" -ForegroundColor Yellow
        }
        "windows" {
            Write-Host "  Windows Setup erfolgreich" -ForegroundColor Green
            # Überprüfe Visual Studio Build Tools
            $vsPath = Get-Command cl.exe -ErrorAction SilentlyContinue
            if (-not $vsPath) {
                Write-Host "  ⚠️  Visual Studio Build Tools möglicherweise nicht installiert" -ForegroundColor Yellow
            }
        }
        "web" {
            Write-Host "  Web-Unterstützung aktiviert" -ForegroundColor Green
        }
        default {
            Write-Host "  Unbekannte Plattform: $Platform" -ForegroundColor Red
            exit 1
        }
    }
}

# 7. Abschluss
Write-Host ""
Write-Host "✅ Setup abgeschlossen!" -ForegroundColor Green
Write-Host ""

Write-Host "Verfügbare Geräte:" -ForegroundColor Cyan
flutter devices 2>$null

Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Entwicklung starten:" -ForegroundColor Yellow
Write-Host "    flutter run -d <device>" -ForegroundColor Gray
Write-Host ""

Write-Host "  Projekt bauen:" -ForegroundColor Yellow
Write-Host "    flutter build <platform>" -ForegroundColor Gray
Write-Host ""

Write-Host "  Tests ausführen:" -ForegroundColor Yellow
Write-Host "    flutter test" -ForegroundColor Gray
Write-Host ""

Write-Host "  Code-Analyse:" -ForegroundColor Yellow
Write-Host "    flutter analyze" -ForegroundColor Gray
Write-Host ""

Write-Host "Weitere Informationen:" -ForegroundColor Cyan
Write-Host "  https://flutter.dev/docs/get-started" -ForegroundColor Gray
Write-Host "  Lokale Dokumentation: INSTALLATION.md" -ForegroundColor Gray
Write-Host ""
