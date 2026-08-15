# setup.ps1 - Automatisiertes Projekt-Setup für Finance Analyzer
# Verwendung: .\setup.ps1 [-SkipDoctor] [-NoBuildRunner] [-Platform <platform>]

param(
    [switch]$SkipDoctor,
    [switch]$NoBuildRunner,
    [string]$Platform = ""
)

# Fehlerbehandlung
$ErrorActionPreference = "Continue"

# Header
Write-Host ""
Write-Host "Finance Analyzer - Setup-Skript" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 1. Flutter Installation überprüfen
Write-Host "[+] Pruefe Flutter-Installation..." -ForegroundColor Yellow
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "[ERROR] Flutter nicht gefunden!" -ForegroundColor Red
    Write-Host "Bitte installieren: https://flutter.dev/docs/get-started/install" -ForegroundColor Red
    exit 1
}

$flutterVersion = flutter --version 2>$null | Select-Object -First 1
Write-Host "  $flutterVersion" -ForegroundColor Green

# 2. Flutter Doctor (optional)
if (-not $SkipDoctor) {
    Write-Host ""
    Write-Host "[+] Fuehre flutter doctor aus..." -ForegroundColor Yellow
    flutter doctor -v
}

# 3. Flutter Clean
Write-Host ""
Write-Host "[+] Raeume auf (flutter clean)..." -ForegroundColor Yellow
flutter clean

# 4. Abhaengigkeiten abrufen
Write-Host "[+] Lade Flutter-Abhaengigkeiten..." -ForegroundColor Yellow
flutter pub get

# 5. Build Runner (optional)
if (-not $NoBuildRunner) {
    Write-Host "[+] Generiere Code (build_runner)..." -ForegroundColor Yellow
    flutter pub run build_runner build --delete-conflicting-outputs
}

# 6. Plattform-spezifisches Setup
if ($Platform) {
    Write-Host ""
    Write-Host "[+] Plattform-Setup: $Platform" -ForegroundColor Yellow

    switch ($Platform.ToLower()) {
        "android" {
            Write-Host "  Ueberpruefen Android-Umgebung..." -ForegroundColor Gray
            $adb = Get-Command adb -ErrorAction SilentlyContinue
            if (-not $adb) {
                Write-Host "  [WARN] adb nicht gefunden" -ForegroundColor Yellow
            }
            else {
                adb devices
            }
        }
        "ios" {
            Write-Host "  [INFO] iOS nur auf macOS verfuegbar" -ForegroundColor Yellow
        }
        "macos" {
            Write-Host "  [INFO] macOS nur auf macOS verfuegbar" -ForegroundColor Yellow
        }
        "linux" {
            Write-Host "  [INFO] Linux nur auf Linux verfuegbar" -ForegroundColor Yellow
        }
        "windows" {
            Write-Host "  Windows Setup erfolgreich" -ForegroundColor Green
        }
        "web" {
            Write-Host "  Web-Unterstuetzung aktiviert" -ForegroundColor Green
        }
        default {
            Write-Host "  Unbekannte Plattform: $Platform" -ForegroundColor Red
            exit 1
        }
    }
}

# 7. Abschluss
Write-Host ""
Write-Host "[OK] Setup abgeschlossen!" -ForegroundColor Green
Write-Host ""

Write-Host "Verfuegbare Geraete:" -ForegroundColor Cyan
flutter devices 2>$null

Write-Host ""
Write-Host "Naechste Schritte:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [1] Entwicklung starten:" -ForegroundColor Yellow
Write-Host "      flutter run -d <device>" -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] Projekt bauen:" -ForegroundColor Yellow
Write-Host "      flutter build <platform>" -ForegroundColor Gray
Write-Host ""
Write-Host "  [3] Tests ausfuehren:" -ForegroundColor Yellow
Write-Host "      flutter test" -ForegroundColor Gray
Write-Host ""
Write-Host "Weitere Informationen:" -ForegroundColor Cyan
Write-Host "  https://flutter.dev/docs/get-started" -ForegroundColor Gray
Write-Host "  Lokale Dokumentation: INSTALLATION.md" -ForegroundColor Gray
Write-Host ""
