#!/bin/zsh
#
# Captures d'écran App Store, entièrement automatiques, via le mode démo de l'app
# (-UIScreenshotMode, cf. iOS tools/SpeedTest/GUI/HeatMap/DemoData.swift) :
#   - heat map et mesure : sondes pré-remplies, aucune dépendance réseau ;
#   - découverte : réseau domestique fictif (DBMaster.addDefaultNodes), la vraie
#     découverte réseau est ignorée — aucune donnée réelle dans les captures.
#
# Formats produits = ceux qu'App Store Connect exige (tous les autres formats
# d'appareils iPhone/iPad sont déduits par réduction automatique) :
#   iphone69 : iPhone 6,9"   (iPhone 17 Pro Max)      1320 x 2868 portrait
#   ipad13   : iPad 13"      (iPad Pro 13-inch M5)    2064 x 2752 portrait
#   ipad13-landscape : le même iPad en paysage,       2752 x 2064 — seconde passe sur le
#              même simulateur, après la série portrait. Ni l'app (iPadOS refuse la rotation
#              par programme en mode fenêtré : UISceneErrorDomain 101) ni simctl ne savent
#              tourner l'appareil : c'est un test d'interface XCTest (scripts/SimRotator,
#              XCUIDevice.orientation) qui le fait pivoter, sans autorisation macOS (~1 min).
#   mac      : app Mac Catalyst, fenêtre figée à 1440 x 900 points par le mode démo ;
#              après composition 2880 x 1800 (écran Retina) ou 1440 x 900 (non Retina),
#              deux formats 16:10 acceptés. Nécessite l'autorisation « Enregistrement
#              de l'écran » pour le Terminal (screencapture).
# Source : developer.apple.com/help/app-store-connect/reference/screenshot-specifications
#
# Usage :
#   scripts/screenshots.sh [-l en-US,fr-FR,es-ES] [-d iphone69,ipad13,ipad13-landscape,mac] [-o répertoire] [-n]
#     -l  locales App Store à produire (défaut : toutes celles de screenshot-captions.tsv)
#     -d  appareils à capturer (défaut : iphone69,ipad13,ipad13-landscape,mac)
#     -o  répertoire de sortie (défaut : ASO/screenshots, non versionné)
#     -n  captures brutes seulement, sans composition des bandeaux
#     -s  écrans à capturer (ex. measure,traces ; défaut : tous ceux du TSV), pour reprendre
#         quelques captures ratées
#     -B  sans compilation : réutilise les produits déjà compilés (pour lancer plusieurs
#         instances en parallèle, une par appareil, après une première compilation)
#   « ipad13-landscape » seul ne capture que le paysage ; avec « ipad13 », les deux passes.
#
# Sortie :
#   <out>/raw/<langue simulateur>/<appareil>/<scénario>.png   captures brutes
#   <out>/<locale>/<appareil>/<index>_<scénario>.png           prêtes pour ASC
#                                                              (bandeau texte, sans alpha)
#   <out>/<locale>/<appareil>-frise/<index>_<scénario>.png     variante « frise » : appareils
#                                                              dessinés en perspective sur un
#                                                              fond continu (iPhone, iPad
#                                                              paysage, Mac) — celle à publier
#
# Les légendes (texte indexé par Apple) sont dans scripts/screenshot-captions.tsv :
# une ligne par locale x écran (index = ordre d'affichage dans ASC). Les écrans capturés
# sont ceux que ce fichier liste pour les locales demandées.
#
set -euo pipefail

ROOT="${0:A:h:h}"
WS="$ROOT/iOS tools.xcodeproj.xcworkspace"
SCHEME="iOS tools"
BUNDLE_ID="net.fenyo.apple.wifi-map-explorer"
CAPTIONS="$ROOT/scripts/screenshot-captions.tsv"
OUT="$ROOT/ASO/screenshots"
DD="${${TMPDIR:-/tmp}%/}/screenshots-dd"
LOCALES=""
DEVICES="iphone69,ipad13,ipad13-landscape,mac"
COMPOSE=1
SKIP_BUILD=0
ONLY_SCENARIOS=""

while getopts "l:d:o:nBs:" opt; do
    case $opt in
        l) LOCALES="$OPTARG" ;;
        d) DEVICES="$OPTARG" ;;
        o) OUT="$OPTARG" ;;
        n) COMPOSE=0 ;;
        B) SKIP_BUILD=1 ;;
        s) ONLY_SCENARIOS="$OPTARG" ;;
        *) sed -n '2,30p' "$0"; exit 1 ;;
    esac
done

# Simulateurs : clé -> type d'appareil, nom du simulateur dédié, dimensions attendues
typeset -A DEVTYPE DEVNAME DEVSIZE
DEVTYPE=(iphone69 com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max
         ipad13   com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB)
DEVNAME=(iphone69 "ASC iPhone 6.9" ipad13 "ASC iPad 13")
DEVSIZE=(iphone69 "1320x2868" ipad13 "2064x2752" ipad13-landscape "2752x2064")

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

# Scénarios (écrans) à capturer : ceux du TSV pour les locales demandées, cf. la liste
# des scénarios dans DemoData.swift (welcome, heatmap, measure, discover, details, 3d, traces)
if [[ -n "$LOCALES" ]]; then
    SCENARIOS=(${(u)$(awk -F'\t' -v f="$filter" 'NR>1 && index(f, "," $1 ",") {print $4}' "$CAPTIONS")})
else
    SCENARIOS=(${(u)$(awk -F'\t' 'NR>1 {print $4}' "$CAPTIONS")})
fi
[[ -n "$ONLY_SCENARIOS" ]] && SCENARIOS=(${(s:,:)ONLY_SCENARIOS})
echo "=== écrans : $SCENARIOS"

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

SIM_KEYS=(${(s:,:)DEVICES})
SIM_KEYS=(${SIM_KEYS:#mac})
WANT_LANDSCAPE=0; WANT_PORTRAIT=0
(( ${SIM_KEYS[(Ie)ipad13]} )) && WANT_PORTRAIT=1
if (( ${SIM_KEYS[(Ie)ipad13-landscape]} )); then
    WANT_LANDSCAPE=1
    SIM_KEYS=(${SIM_KEYS:#ipad13-landscape})
    (( ${SIM_KEYS[(Ie)ipad13]} )) || SIM_KEYS+=(ipad13)
fi

# Orientation courante d'un simulateur iPad, déduite de la taille d'une capture
sim_orientation() {
    local shot="${TMP_SHOT%.png}-orient.png" w
    xcrun simctl io "$1" screenshot --type png "$shot" > /dev/null 2>&1
    w=$(sips -g pixelWidth "$shot" | awk '/pixelWidth/{print $2}'); rm -f "$shot"
    [[ $w == 2064 ]] && echo portrait || echo landscape
}

# Pivote le simulateur par le test d'interface SimRotator : <udid> <portrait|landscape>
wait_orientation() {
    [[ $(sim_orientation $1) == $2 ]] && return
    echo "  rotation en $2 (test d'interface SimRotator)"
    TEST_RUNNER_SIM_ORIENTATION=$2 xcodebuild test-without-building -xctestrun "$ROTATOR_RUN" \
        -destination "id=$1" > "${TMP_SHOT%.png}-rotator.log" 2>&1 \
        || { echo "  ERREUR  rotation impossible, cf. ${TMP_SHOT%.png}-rotator.log"; exit 1; }
    sleep 3
    [[ $(sim_orientation $1) == $2 ]] || { echo "  ERREUR  l'iPad n'est pas en $2 après rotation"; exit 1; }
}
WANT_MAC=0; [[ ",$DEVICES," == *,mac,* ]] && WANT_MAC=1

errors=0
TMP_SHOT="$(mktemp -d)/shot.png"

check_size() {   # <png> <libellé> <tailles acceptées séparées par des espaces>
    local size
    size=$(sips -g pixelWidth -g pixelHeight "$1" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w "x" h}')
    if [[ " $3 " == *" $size "* ]]; then
        echo "  ok  $2 ($size)"
    else
        echo "  ERREUR  $2 : $size au lieu de $3"
        errors=$((errors + 1))
    fi
}

if (( ${#SIM_KEYS} > 0 )); then
echo "=== build simulateur (Debug : le mode démo n'existe pas en Release)"
# ARCHS=arm64 : la lib net-snmp simulateur n'a pas de tranche x86_64
(( SKIP_BUILD )) || xcodebuild -workspace "$WS" -scheme "$SCHEME" -configuration Debug \
           -destination "generic/platform=iOS Simulator" \
           ARCHS=arm64 ONLY_ACTIVE_ARCH=NO -skipMacroValidation \
           -derivedDataPath "$DD" build | grep -E "BUILD (SUCCEEDED|FAILED)"
APP="$DD/Build/Products/Debug-iphonesimulator/iOS tools.app"
if [[ ${SIM_KEYS[(Ie)ipad13]} -gt 0 ]]; then
    # Test d'interface qui pivote le simulateur iPad (série paysage, retour en portrait)
    echo "=== build SimRotator (rotation du simulateur)"
    (( SKIP_BUILD )) || xcodebuild build-for-testing -project "$ROOT/scripts/SimRotator/SimRotator.xcodeproj" \
               -scheme SimRotator -destination "generic/platform=iOS Simulator" \
               -derivedDataPath "$DD-rotator" | grep -E "BUILD (SUCCEEDED|FAILED)"
    ROTATOR_RUN=$(print -l "$DD-rotator"/Build/Products/SimRotator_iphonesimulator*.xctestrun(N) | head -1)
    [[ -n "$ROTATOR_RUN" ]] || { echo "  ERREUR  SimRotator : .xctestrun introuvable"; exit 1; }
fi
fi

for key in $SIM_KEYS; do
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

    # Passes : portrait, puis paysage sur le même simulateur iPad si demandé
    passes=($key)
    if [[ $key == ipad13 ]]; then
        passes=()
        (( WANT_PORTRAIT )) && passes+=(ipad13)
        (( WANT_LANDSCAPE )) && passes+=(ipad13-landscape)
    fi
    for out_key in $passes; do
    if [[ $key == ipad13 ]]; then
        [[ $out_key == ipad13-landscape ]] && wait_orientation "$udid" landscape || wait_orientation "$udid" portrait
    fi
    for lang in $LANGS; do
        for scenario in $SCENARIOS; do
            dir="$OUT/raw/$lang/$out_key"; mkdir -p "$dir"
            png="$dir/$scenario.png"
            xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
            xcrun simctl launch "$udid" "$BUNDLE_ID" \
                -UIScreenshotMode -UIScreenshotScenario "$scenario" \
                -AppleLanguages "($lang)" -AppleLocale "$lang" > /dev/null
            # Délai avant capture : la vue 3D se peuple puis bascule en mode 3D ; l'accueil
            # garde une marge sur l'animation du modal ; ailleurs, carte (1 Hz) + fondu.
            # Mesure sur iPad : le calcul de la carte (IDW) sur la grande image est plus long
            # Découverte sur iPad : courbe de latence fictive injectée par le mode démo
            case $key:$scenario in
                ipad13:discover) sleep 15 ;;
                *:measure|*:heatmap) sleep 20 ;;   # calcul de la carte (IDW), plus long sur grande image ou machine chargée
                *:3d) sleep 40 ;;   # plus lent à se peupler sur iPhone (et machine chargée)
                *:welcome|*:details) sleep 12 ;;
                *) sleep 9 ;;
            esac
            # Capture dans un répertoire temporaire puis déplacement : le service du
            # simulateur qui écrit l'image n'a pas accès aux volumes externes (le dépôt
            # est sur /Volumes/external-mac) et échoue en « Operation not permitted »
            xcrun simctl io "$udid" screenshot --type png "$TMP_SHOT" 2>&1 | grep -vE "^(Note|Wrote)" || true
            [[ -s "$TMP_SHOT" ]] || { echo "  ERREUR  capture impossible : $lang/$out_key/$scenario"; exit 1; }
            mv -f "$TMP_SHOT" "$png"
            check_size "$png" "$lang/$out_key/$scenario.png" "${DEVSIZE[$out_key]}"
        done
    done
    done
    xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl status_bar "$udid" clear
done

if (( WANT_MAC )); then
    if [[ "$(ioreg -n Root -d1)" == *'"IOConsoleLocked" = Yes'* ]]; then
        echo "=== ERREUR : écran verrouillé, macOS interdit les captures de fenêtres Mac"; exit 1
    fi
    echo "=== build Mac Catalyst (Debug)"
    (( SKIP_BUILD )) || xcodebuild -workspace "$WS" -scheme "$SCHEME" -configuration Debug \
               -destination "platform=macOS,variant=Mac Catalyst,arch=arm64" -skipMacroValidation \
               -derivedDataPath "$DD" build | grep -E "BUILD (SUCCEEDED|FAILED)"
    MAC_APP="$DD/Build/Products/Debug-maccatalyst/iOS tools.app"
    MAC_BIN="$MAC_APP/Contents/MacOS/iOS tools"
    WINID_TOOL="$(mktemp -d)/mac-window-id"
    swiftc -O -o "$WINID_TOOL" "$ROOT/scripts/mac-window-id.swift"
    echo "=== Mac (fenêtre 1440x900 points)"
    for lang in $LANGS; do
        for scenario in $SCENARIOS; do
            dir="$OUT/raw/$lang/mac"; mkdir -p "$dir"
            png="$dir/$scenario.png"
            pkill -f "Debug-maccatalyst/iOS tools.app" 2>/dev/null || true
            sleep 1
            # « open » active l'app : fenêtre au premier plan (boutons de fenêtre en couleur),
            # contrairement au lancement direct de l'exécutable depuis le Terminal
            open -n "$MAC_APP" --args -UIScreenshotMode -UIScreenshotScenario "$scenario" \
                 -AppleLanguages "($lang)" -AppleLocale "$lang"
            # démarrage, carte, scène 3D ; découverte : courbe de latence fictive
            case $scenario in discover) sleep 15 ;; 3d) sleep 18 ;; *) sleep 12 ;; esac
            # Recherche par la fin du chemin : LaunchServices normalise le chemin complet
            mac_pid=$(pgrep -n -f "Debug-maccatalyst/iOS tools.app/Contents/MacOS/iOS tools") \
                || { echo "  ERREUR  l'app Mac ne s'est pas lancée"; exit 1; }
            winid=$("$WINID_TOOL" $mac_pid) || { echo "  ERREUR  fenêtre introuvable : $lang/mac/$scenario"; exit 1; }
            # Pas de « | grep -q » : sous pipefail, l'arrêt anticipé de grep fait échouer ioreg
            if [[ "$(ioreg -n Root -d1)" == *'"IOConsoleLocked" = Yes'* ]]; then
                echo "  ERREUR  écran verrouillé : macOS interdit les captures de fenêtres"; exit 1
            fi
            # -o : sans l'ombre de la fenêtre ; -x : sans son
            screencapture -x -o -l "$winid" "$TMP_SHOT"
            mv -f "$TMP_SHOT" "$png"
            # Catalyst applique sa propre échelle au cadre demandé (1296x810 observé pour
            # 1440x900 demandés) : on exige seulement du 16:10 assez grand, la composition
            # ramène ensuite au format ASC exact (1440x900 ou 2880x1800)
            read w h <<< "$(sips -g pixelWidth -g pixelHeight "$png" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w, h}')"
            if (( w >= 1200 && w * 10 == h * 16 )); then
                echo "  ok  $lang/mac/$scenario.png (${w}x$h)"
            else
                echo "  ERREUR  $lang/mac/$scenario.png : ${w}x$h (attendu 16:10, largeur >= 1200)"
                errors=$((errors + 1))
            fi
            kill $mac_pid 2>/dev/null || true
        done
    done
    pkill -f "Debug-maccatalyst/iOS tools.app" 2>/dev/null || true
fi

(( errors == 0 )) || { echo "=== $errors capture(s) aux mauvaises dimensions, composition annulée"; exit 1; }
echo "=== captures brutes dans $OUT/raw"

if (( COMPOSE )); then
    echo "=== composition des bandeaux"
    swift "$ROOT/scripts/compose-screenshots.swift" "$OUT" "$LOCALES"
    echo "=== frises (appareils en perspective, cf. frise-screenshots.swift)"
    swift "$ROOT/scripts/frise-screenshots.swift" "$OUT" "$LOCALES"
    for f in "$OUT"/${~${LOCALES:+(${LOCALES//,/|})}:-*}/mac-frise/[0-9]*.png(N); do
        check_size "$f" "${f#$OUT/}" "2880x1800 1440x900"
    done
    for f in "$OUT"/${~${LOCALES:+(${LOCALES//,/|})}:-*}/mac/*.png(N); do
        check_size "$f" "${f#$OUT/}" "2880x1800 1440x900"
    done
    echo "=== captures prêtes pour App Store Connect dans $OUT/<locale>/<appareil>/"
fi
