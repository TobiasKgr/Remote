#!/bin/bash
# setup.sh - Automatisiertes Projekt-Setup für Finance Analyzer
# Verwendung: ./setup.sh [--skip-doctor] [--no-build-runner]

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
SKIP_DOCTOR=false
NO_BUILD_RUNNER=false
TARGET_PLATFORM=""

# Argumente verarbeiten
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-doctor)
            SKIP_DOCTOR=true
            shift
            ;;
        --no-build-runner)
            NO_BUILD_RUNNER=true
            shift
            ;;
        --platform)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        *)
            echo "Unbekanntes Argument: $1"
            echo "Verwendung: ./setup.sh [--skip-doctor] [--no-build-runner] [--platform android|ios|macos|windows|linux|web]"
            exit 1
            ;;
    esac
done

# Header
echo -e "${BLUE}"
echo "🚀 Finance Analyzer - Setup-Skript"
echo "===================================="
echo -e "${NC}"

# 1. Flutter Installation überprüfen
echo -e "${YELLOW}✓ Prüfe Flutter-Installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter nicht gefunden!${NC}"
    echo "Bitte installieren: https://flutter.dev/docs/get-started/install"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}  $FLUTTER_VERSION${NC}"

# 2. Flutter Doctor (optional)
if [ "$SKIP_DOCTOR" = false ]; then
    echo -e "${YELLOW}✓ Führe 'flutter doctor' aus...${NC}"
    flutter doctor -v
    echo ""
fi

# 3. Flutter Clean
echo -e "${YELLOW}✓ Räume auf (flutter clean)...${NC}"
flutter clean

# 4. Abhängigkeiten abrufen
echo -e "${YELLOW}✓ Lade Flutter-Abhängigkeiten...${NC}"
flutter pub get

# 5. Build Runner (optional)
if [ "$NO_BUILD_RUNNER" = false ]; then
    echo -e "${YELLOW}✓ Generiere Code (build_runner)...${NC}"
    flutter pub run build_runner build --delete-conflicting-outputs
fi

# 6. Plattform-spezifische Setups
if [ -n "$TARGET_PLATFORM" ]; then
    echo -e "${YELLOW}✓ Führe plattformspezifisches Setup aus: $TARGET_PLATFORM${NC}"

    case $TARGET_PLATFORM in
        android)
            echo "  Überprüfe Android-Umgebung..."
            if ! command -v adb &> /dev/null; then
                echo -e "${RED}  ⚠️  adb nicht gefunden${NC}"
            else
                adb devices
            fi
            ;;
        ios)
            if [[ "$OSTYPE" != "darwin"* ]]; then
                echo -e "${RED}  ⚠️  iOS nur auf macOS verfügbar${NC}"
            else
                echo "  Überprüfe iOS/Xcode..."
                xcode-select --version
            fi
            ;;
        macos)
            if [[ "$OSTYPE" != "darwin"* ]]; then
                echo -e "${RED}  ⚠️  macOS nur auf macOS verfügbar${NC}"
            else
                echo "  macOS Setup erfolgreich"
            fi
            ;;
        linux)
            echo "  Überprüfe Linux-Abhängigkeiten..."
            if ! command -v pkg-config &> /dev/null; then
                echo -e "${YELLOW}  ⚠️  pkg-config nicht gefunden - Linux Desktop funktioniert möglicherweise nicht${NC}"
            fi
            ;;
        windows)
            if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
                echo "  Windows Setup erfolgreich"
            else
                echo -e "${RED}  ⚠️  Windows nur auf Windows verfügbar${NC}"
            fi
            ;;
        web)
            echo "  Web-Unterstützung aktiviert"
            ;;
        *)
            echo -e "${RED}  Unbekannte Plattform: $TARGET_PLATFORM${NC}"
            exit 1
            ;;
    esac
fi

# 7. Abschluss
echo ""
echo -e "${GREEN}✅ Setup abgeschlossen!${NC}"
echo ""
echo -e "${BLUE}Verfügbare Geräte:${NC}"
flutter devices || true

echo ""
echo -e "${BLUE}Nächste Schritte:${NC}"
echo -e "  ${YELLOW}Entwicklung starten:${NC}"
echo "    flutter run -d <device>"
echo ""
echo -e "  ${YELLOW}Projekt bauen:${NC}"
echo "    flutter build <platform>"
echo ""
echo -e "  ${YELLOW}Tests ausführen:${NC}"
echo "    flutter test"
echo ""
echo -e "  ${YELLOW}Code-Analyse:${NC}"
echo "    flutter analyze"
echo ""
echo -e "${BLUE}Weitere Informationen:${NC}"
echo "  https://flutter.dev/docs/get-started"
echo "  Lokale Dokumentation: INSTALLATION.md"
