#!/bin/zsh
#
# Captures d'écran App Store, entièrement automatiques, via le mode démo de l'app
# (-UIScreenshotMode, cf. iOS tools/SpeedTest/GUI/HeatMap/DemoData.swift) :
#   - heat map et mesure : sondes pré-remplies, aucune dépendance réseau ;
#   - découverte : réseau domestique fictif (DBMaster.addDefaultNodes), la vraie
#     découverte réseau est ignorée — aucune donnée réelle dans les captures.
#
# Formats produits = les deux seuls qu'App Store Connect exige (tous les autres
# formats d'appareils sont déduits par réduction automatique) :
#   iphone69 : iPhone 6,9"   (iPhone 17 Pro Max)      1320 x 2868 portrait
#   ipad13   : iPad 13"      (iPad Pro 13-inch M5)    2064 x 2752 portrait
# Source : developer.apple.com/help/app-store-connect/reference/screenshot-specifications
#
# Usage :
#   scripts/screenshots.sh [-l en-US,fr-FR,es-ES] [-o répertoire] [-n]
#     -l  locales App Store à produire (défaut : toutes celles de screenshot-captions.tsv)
#     -o  répertoire de sortie (défaut : ASO/screenshots, non versionné)
#     -n  captures brutes seulement, sans composition des bandeaux
#
# Sortie :
#   <out>/raw/<langue simulateur>/<appareil>/<scénario>.png   captures brutes
#   <out>/<locale>/<appareil>/<index>_<scénario>.png           prêtes pour ASC
#                                                              (bandeau texte, sans alpha)
#
# Les légendes (texte indexé par Apple) sont dans scripts/screenshot-captions.tsv ;
# une ligne par locale x scénario. Ajouter une locale = y ajouter 3 lignes.
#
set -euo pipefail

ROOT="${0:A:h:h}"
WS="$ROOT/iOS tools.xcodeproj.xcworkspace"
SCHEME="iOS tools"
BUNDLE_ID="net.fenyo.apple.wifi-map-explorer"
CAPTIONS="$ROOT/scripts/screenshot-captions.tsv"
OUT="$ROOT/ASO/screenshots"
DD="${TMPDIR:-/tmp}/screenshots-dd"
LOCALES=""
COMPOSE=1

while getopts "l:o:n" opt; do
    case $opt in
        l) LOCALES="$OPTARG" ;;
        o) OUT="$OPTARG" ;;
        n) COMPOSE=0 ;;
        *) sed -n '2,30p' "$0"; exit 1 ;;
    esac
done

# Simulateurs : clé -> type d'appareil, nom du simulateur dédié, dimensions attendues
typeset -A DEVTYPE DEVNAME DEVSIZE
DEVTYPE=(iphone69 com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max
         ipad13   com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB)
DEVNAME=(iphone69 "ASC iPhone 6.9" ipad13 "ASC iPad 13")
DEVSIZE=(iphone69 "1320x2868" ipad13 "2064x2752")
SCENARIOS=(heatmap measure discover)

# Langues du simulateur à capturer, déduites du TSV (plusieurs locales App Store
# peuvent partager une langue, ex. nl-NL et it utilisent l'interface anglaise)
if [[ -n "$LOCALES" ]]; then
    filter=",$LOCALES,"
    LANGS=(${(u)$(awk -F'\t' -v f="$filter" 'NR>1 && index(f, "," $1 ",") {print $2}' "$CAPTIONS")})
else
    LANGS=(${(u)$(awk -F'\t' 'NR>1 {print $2}' "$CAPTIONS")})
fi
(( ${#LANGS} > 0 )) || { echo "aucune locale trouvée dans $CAPTIONS pour '$LOCALES'"; exit 1; }
echo "=== langues simulateur : $LANGS"

# Runtime iOS le plus récent installé
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
rts = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]]
rts.sort(key=lambda r: [int(x) for x in r["version"].split(".")])
print(rts[-1]["identifier"])')
echo "=== runtime : $RUNTIME"

# Retrouve (ou crée) le simulateur dédié à un format, sur ce runtime
sim_udid() {
    local key=$1 name="${DEVNAME[$1]}" udid
    udid=$(xcrun simctl list devices -j | python3 -c '
import json, sys
name, rt = sys.argv[1], sys.argv[2]
for d in json.load(sys.stdin)["devices"].get(rt, []):
    if d["name"] == name and d["isAvailable"]:
        print(d["udid"]); break' "$name" "$RUNTIME")
    [[ -n "$udid" ]] || udid=$(xcrun simctl create "$name" "${DEVTYPE[$key]}" "$RUNTIME")
    echo "$udid"
}

echo "=== build simulateur (Debug : le mode démo n'existe pas en Release)"
# ARCHS=arm64 : la lib net-snmp simulateur n'a pas de tranche x86_64
xcodebuild -workspace "$WS" -scheme "$SCHEME" -configuration Debug \
           -destination "generic/platform=iOS Simulator" \
           ARCHS=arm64 ONLY_ACTIVE_ARCH=NO -skipMacroValidation \
           -derivedDataPath "$DD" build | grep -E "BUILD (SUCCEEDED|FAILED)"
APP="$DD/Build/Products/Debug-iphonesimulator/iOS tools.app"

errors=0
TMP_SHOT="$(mktemp -d)/shot.png"
for key in iphone69 ipad13; do
    udid=$(sim_udid $key)
    echo "=== ${DEVNAME[$key]} ($udid), attendu ${DEVSIZE[$key]}"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b > /dev/null
    # Juste après le premier démarrage d'un simulateur neuf, SpringBoard n'est pas encore
    # prêt et ces réglages échouent : on réessaie quelques secondes
    for attempt in 1 2 3 4 5 6; do
        # Barre d'état reproductible (heure et batterie identiques dans toutes les langues)
        if xcrun simctl ui "$udid" appearance light 2>/dev/null &&
           xcrun simctl status_bar "$udid" override \
               --time "9:41" --batteryState charged --batteryLevel 100 \
               --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 \
               --dataNetwork wifi 2>/dev/null; then
            break
        fi
        (( attempt < 6 )) || { echo "  impossible de régler apparence / barre d'état"; exit 1; }
        sleep 5
    done
    xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl install "$udid" "$APP"

    for lang in $LANGS; do
        for scenario in $SCENARIOS; do
            dir="$OUT/raw/$lang/$key"; mkdir -p "$dir"
            png="$dir/$scenario.png"
            xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
            xcrun simctl launch "$udid" "$BUNDLE_ID" \
                -UIScreenshotMode -UIScreenshotScenario "$scenario" \
                -AppleLanguages "($lang)" -AppleLocale "$lang" > /dev/null
            sleep 9   # calcul de la carte (1 Hz) + fondu
            # Capture dans un répertoire temporaire puis déplacement : le service du
            # simulateur qui écrit l'image n'a pas accès aux volumes externes (le dépôt
            # est sur /Volumes/external-mac) et échoue en « Operation not permitted »
            xcrun simctl io "$udid" screenshot --type png "$TMP_SHOT" 2>&1 | grep -vE "^(Note|Wrote)" || true
            [[ -s "$TMP_SHOT" ]] || { echo "  ERREUR  capture impossible : $lang/$key/$scenario"; exit 1; }
            mv -f "$TMP_SHOT" "$png"
            size=$(sips -g pixelWidth -g pixelHeight "$png" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w "x" h}')
            if [[ "$size" == "${DEVSIZE[$key]}" ]]; then
                echo "  ok  $lang/$key/$scenario.png ($size)"
            else
                echo "  ERREUR  $lang/$key/$scenario.png : $size au lieu de ${DEVSIZE[$key]}"
                errors=$((errors + 1))
            fi
        done
    done
    xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl status_bar "$udid" clear
done

(( errors == 0 )) || { echo "=== $errors capture(s) aux mauvaises dimensions, composition annulée"; exit 1; }
echo "=== captures brutes dans $OUT/raw"

if (( COMPOSE )); then
    echo "=== composition des bandeaux"
    swift "$ROOT/scripts/compose-screenshots.swift" "$OUT" "$LOCALES"
    echo "=== captures prêtes pour App Store Connect dans $OUT/<locale>/<appareil>/"
fi
