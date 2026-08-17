#!/bin/zsh
#
# Capture automatique des captures d'écran App Store, via le mode démo
# (-UIScreenshotMode, cf. DemoData.swift). Aucune interaction manuelle :
# l'app navigue toute seule vers l'écran voulu.
#
# Usage :
#   scripts/screenshots.sh [répertoire-de-sortie]
#
# Produit, pour chaque langue embarquée (en, en-GB, fr, es), chaque scénario
# (heatmap, measure, discover) et chaque appareil requis par App Store Connect
# (iPhone 6,9" 1320x2868, iPad 13" 2064x2752) :
#   <out>/raw/<langue>/<appareil>/<scénario>.png
#
# La composition du bandeau texte (indexé par Apple) se fait ensuite avec
# scripts/compose-screenshots.swift.
#
set -euo pipefail

ROOT="${0:A:h:h}"
WS="$ROOT/iOS tools.xcodeproj.xcworkspace"
SCHEME="iOS tools"
BUNDLE_ID="net.fenyo.apple.wifi-map-explorer"
OUT="${1:-$ROOT/ASO/screenshots}"
DD="${TMPDIR:-/tmp}/screenshots-dd"

typeset -A DEVICES
DEVICES=(iphone69 "iPhone 17 Pro Max" ipad13 "iPad Pro 13-inch (M5)")
LANGS=(en en-GB fr es)
SCENARIOS=(heatmap measure discover)

echo "=== build simulateur"
# ARCHS=arm64 : la lib net-snmp simulateur n'a pas de tranche x86_64
xcodebuild -workspace "$WS" -scheme "$SCHEME" -configuration Debug \
           -destination "generic/platform=iOS Simulator" \
           ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
           -derivedDataPath "$DD" build | grep -E "BUILD (SUCCEEDED|FAILED)"
APP="$DD/Build/Products/Debug-iphonesimulator/iOS tools.app"

for dev_key in ${(k)DEVICES}; do
    dev="${DEVICES[$dev_key]}"
    echo "=== $dev"
    xcrun simctl boot "$dev" 2>/dev/null || true
    xcrun simctl bootstatus "$dev" -b
    # Barre d'état reproductible (l'heure et la batterie ne varient pas entre langues)
    xcrun simctl status_bar "$dev" override \
        --time "9:41" --batteryState charged --batteryLevel 100 \
        --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --dataNetwork wifi
    xcrun simctl uninstall "$dev" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl install "$dev" "$APP"

    for lang in $LANGS; do
        for scenario in $SCENARIOS; do
            dir="$OUT/raw/$lang/$dev_key"; mkdir -p "$dir"
            xcrun simctl terminate "$dev" "$BUNDLE_ID" 2>/dev/null || true
            xcrun simctl launch "$dev" "$BUNDLE_ID" \
                -UIScreenshotMode -UIScreenshotScenario "$scenario" \
                -AppleLanguages "($lang)" -AppleLocale "$lang" > /dev/null
            sleep 9   # calcul de la carte (1 Hz) + fondu
            xcrun simctl io "$dev" screenshot --type png "$dir/$scenario.png" 2>/dev/null
            echo "  $lang/$dev_key/$scenario.png"
        done
    done
    xcrun simctl terminate "$dev" "$BUNDLE_ID" 2>/dev/null || true
done
echo "=== captures brutes dans $OUT/raw"
