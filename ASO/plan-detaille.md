# Redressement ASO — phases 1 & 2 (WiFi Network Tools & Maps)

## Contexte

L'app `net.fenyo.apple.wifi-map-explorer` (App Store id 1662393654) est passée de ~73 à ~11 unités/mois
(−84 %). Le diagnostic (`ASO/Diagnostic ASO & plan d'action.pdf`) établit que **le problème est en haut
du tunnel** : les impressions ont chuté de 88 % (24 879 → 2 886/mois) alors que les taux de conversion
tiennent (impression→fiche s'améliore même : 5,1 % → 7,9 %). La fiche convertit ; elle n'est plus montrée.

Cause racine : le retrait de l'App Store mondial de mars–avril 2025 (plainte du titulaire de la marque
« WiFi Map ») a remis le capital de classement à zéro. L'app est revenue en mai 2025 sous un nouveau nom
**sans qu'aucun champ indexé ne change** — nom, sous-titre, mots-clés, description et captures sont
identiques depuis la version 3.6 (avril 2024).

Objectif de ce plan : exécuter les **phases 1 (aucun dev) et 2 (peu de dev)** du rapport — reconstruire
les champs indexés, ouvrir de nouveaux marchés linguistiques, refaire les captures — et livrer une
version 6.2. Les phases 3 (gratuit + déverrouillage unique) et 4 (acquisition) viendront après.

Décisions prises avec le propriétaire :
- Le nouveau nom sera **arbitré à partir de plusieurs variantes calibrées** que je proposerai avant
  d'écrire quoi que ce soit (le rapport suggère « WiFi Analyzer & Heat Map »).
- L'allemand est traité **côté fiche App Store ET côté interface de l'app** (`de.lproj`).
- Les captures seront produites via un **mode démo intégré**, pour rester reproductibles à chaque version.

## État réel du code (vérifié, y compris dans le binaire construit)

| Constat | Emplacement |
|---|---|
*(Branche de travail : `master`, remise à jour le 16 août 2026 par fast-forward sur `origin/master`,
tip `cf40fd8` du 21 mai 2026. L'ancienne `master` locale datait du 31 mai 2025 et était 100 commits
en retard. Les constats ci-dessous ont été revérifiés sur ce tip.)*

| Constat | Emplacement |
|---|---|
| **Les `INFOPLIST_KEY_*` du pbxproj sont morts** : `GENERATE_INFOPLIST_FILE` absent + `INFOPLIST_FILE` défini ⇒ seul `Info.plist` compte. Vérifié dans le `.app` de DerivedData. | `project.pbxproj:2115,2157` |
| Versions **cohérentes** sur ce tip : `Info.plist` = 6.1.0 / 6.1.0, `MARKETING_VERSION = 6.1`, `CURRENT_PROJECT_VERSION = 26`. La cible est donc **6.2 / build 27**. (Les valeurs 5.3.0 vues sur l'ancienne branche n'existent plus.) Reste que les deux sources sont maintenues à la main en double. | `Info.plist:9-12`, `project.pbxproj:2108,2128` |
| `NSPhotoLibraryUsageDescription` = **« ceci est uyn test »** — affiché à tous les utilisateurs à la 1ʳᵉ demande d'accès photos. Risque de rejet (5.1.1). **Toujours présent.** | `Info.plist:159-160` |
| `NSPhotoLibraryAddUsageDescription` = « Saving **you** heatmap… » (faute) ; `NSLocalNetworkUsageDescription` ne décrit pas l'usage réel. Aucun `InfoPlist.strings` nulle part. | `Info.plist:155-158` |
| 4 noms différents : `WiFi Heatmap & Network Tools` (plist) / `WiFi Network Tools & Maps` (Store, et `INFOPLIST_KEY` mort) / `Network 3D WiFi Tools` (README+site) / `Network Analyzer PRO 3D edition` (captures). | `Info.plist:20`, `project.pbxproj:2115`, `README.md:1` |
| 3 langues : en/fr/es. `en.lproj/Localizable.strings` ne contient qu'1 clé (la clé **est** le texte anglais). fr = **184** clés, es = **188** — le commit `41c7543 « Complete French and Spanish localization »` (mai 2026) a comblé l'essentiel de la dette relevée sur l'ancienne branche. Storyboard toujours traduit à 3/22 en fr. | `iOS tools/{en,fr,es}.lproj/`, `project.pbxproj:1663-1668` |
| Palette heatmap = **rouge → jaune → vert** (teinte HSB 0 → 0,33), LUT de 65 536 `SwiftUI.Color` construite **hors main thread** avec un force-unwrap. | `IDWView.swift:66-86`, légende `:127-146` |
| Les 4 demandes d'avis sont **neutralisées** par une constante globale planquée dans un fichier SNMP ; 2 des 4 sites sont de toute façon mal placés (`onAppear` du panneau de logs et de la vue 3D). | `SNMPView.swift:13` |
| Aucune infra App Store : pas de fastlane, pas de target UITest (dossiers orphelins), `Artwork/screen captures/` = 22 captures brutes. ImageMagick absent de la machine. | — |
| Mode pas-à-pas : plan prédéfini ou photo, chaque tap = 1 mesure, `chargenTCP(51.75.31.39)` lancé automatiquement. Aucun RoomPlan/ARKit/App Intents dans le projet. | `StepByStepSwiftUIView.swift:474-491` |

---

## Étape 0 — Phase 1 du rapport : App Store Connect, sans build *(checklist pour toi)*

À faire en premier, indépendamment du code — effet immédiat, réversible :

1. **Business → Contrats** : vérifier le palier Store Services européen. Tu dois être en **Tier 2**.
   Si Tier 1 → tout le reste est inutile tant que ce n'est pas corrigé.
2. **Texte promotionnel** (170 car., modifiable sans soumettre de version) — remplacer la note de version
   par le texte fourni à l'étape 1.
3. **Ouvrir un compte Apple Ads** (gratuit, 0 € dépensé) et activer le rapport mensuel de classement des
   termes de recherche dans *Insights* — seule source fiable de volumes depuis octobre 2025.
4. **App Store Connect → Métriques → Organigrammes de crash**, semaines du 22 juin et du 3 août 2026
   (34 crashs / 8 semaines à ce volume = un avis 1★ en attente).
5. **Répondre aux 4 avis** « pas de heatmap / pas intuitif » sans réponse.

Je produirai la checklist détaillée avec les valeurs exactes à coller (fichier `ASO/checklist-phase1.md`).

---

## Étape 1 — Métadonnées : variantes puis textes prêts à coller

**1a. Variantes à arbitrer (livrable avant toute écriture).** Un tableau de 4 combinaisons
nom (30 car.) + sous-titre (30 car.) + mots-clés (100 **octets**), avec pour chacune : les termes
réellement gagnés, ceux perdus, et le risque marque. Base de départ : « WiFi Analyzer & Heat Map » /
« Signal strength & speed test ». **Point de vigilance à intégrer** : au-delà de ~12 caractères le nom
est tronqué sous l'icône iOS — le `CFBundleDisplayName` sera donc un préfixe court du nom Store.

**1b. Textes finaux**, versionnés dans `ASO/metadata/<locale>/` puis repris par fastlane (étape 8) :

| Locale | Champs | Note |
|---|---|---|
| `en-US` | name, subtitle, keywords, description (4 000 car., ~1 850 rédigés), promotional text, what's new | Base ; structure du rapport §8, y compris la section « BEFORE YOU BUY — WHAT THIS APP DOES NOT DO » qui désamorce les avis « REVIEWS ARE FAKE, NO HEATMAP » |
| `en-GB` | idem, **mots-clés différents** | Locale de repli de nombreuses vitrines européennes (IE, NL, BE, DK, SE…) : 100 octets indexés gratuits |
| `de-DE` | idem | 2ᵉ marché, 0 métadonnée aujourd'hui. `funkloch, wlan analyse, signalstärke, ausleuchtung…` — **à faire relire par un germanophone** |
| `fr-FR`, `es-ES` | idem | Existent déjà, à réécrire |
| `nl-NL`, `it-IT` | idem | Nouvelles |

⚠️ Apple compte **100 octets**, pas 100 caractères : `ä`, `ü`, `é` en consomment 2. Le calibrage se fait
en octets UTF-8.

**1c. Les localisations App Store Connect sont indépendantes du binaire** (vérifié). Les 100 octets de
mots-clés par locale sont donc gagnables **immédiatement, sans nouveau build**. Seule la liste « Langues »
affichée sur la fiche dérive des `*.lproj` — d'où l'étape 7.

---

## Étape 2 — Correctifs bloquants dans `Info.plist` / `project.pbxproj`

Fichiers : `iOS tools/Info.plist`, `iOS tools.xcodeproj/project.pbxproj`, `README.md`,
`iOS tools/Defaults.swift:144-146`, `StepByStepSwiftUIView.swift:106`.

1. **Supprimer la double saisie des versions** — dans `Info.plist` :
   `CFBundleShortVersionString` → `$(MARKETING_VERSION)`, `CFBundleVersion` → `$(CURRENT_PROJECT_VERSION)` ;
   dans les **deux** configurations du pbxproj : `MARKETING_VERSION = 6.2`, `CURRENT_PROJECT_VERSION = 27`.
   Aujourd'hui les deux sources disent 6.1 et sont maintenues à la main en parallèle — c'est ce qui avait
   dérivé sur l'ancienne branche. → `agvtool` redevient utilisable et le bump devient scriptable.
   **Confirmer d'abord la version/build réellement publiés dans ASC** et prendre `max(publié) + 1`.
2. **Corriger les 3 chaînes de permission** dans `Info.plist` (repli quand aucune locale ne correspond).
   `ceci est uyn test` est le correctif à plus fort ROI immédiat du lot.
3. **Unifier le nom** : `CFBundleDisplayName` = préfixe court du nom Store retenu ; README ligne 1 ;
   libellés de services Bonjour dans `Defaults.swift` (⚠️ **ne pas** toucher aux types `_speedtestchargen._tcp.`
   — compatibilité avec les versions déployées) ; `Text("WiFi Heatmap & Network Tools")` dans l'écran d'accueil.
4. **Ménage** : supprimer `INFOPLIST_KEY_CFBundleDisplayName` et `INFOPLIST_KEY_LSApplicationCategoryType`
   (morts et trompeurs), renseigner `LSApplicationCategoryType` = `public.app-category.utilities` dans
   `Info.plist` (actuellement chaîne vide), et retirer `UIRequiredDeviceCapabilities = [armv7]` (obsolète
   pour une cible iOS 16.6 arm64).

---

## Étape 3 — `InfoPlist.strings` localisés

Créer `iOS tools/{en,fr,es}.lproj/InfoPlist.strings` (au même niveau que `Localizable.strings`), avec
`CFBundleDisplayName` + les 3 descriptions de permission rédigées correctement dans chaque langue.

C'est le **seul point pbxproj délicat** de la release : nouveau `PBXVariantGroup` + `PBXBuildFile` +
entrée dans la phase Resources. → passer par l'UI Xcode (*New File → Strings File*, puis *Localize…*)
plutôt que d'éditer le pbxproj à la main.

Vérification : `plutil -p "<DerivedData>/iOS tools.app/fr.lproj/InfoPlist.strings"`.

---

## Étape 4 — Palette de la heat map

Fichier : `iOS tools/SpeedTest/GUI/HeatMap/IDWView.swift`, lignes 66-86.

Remplacer la LUT HSB rouge→vert par une **rampe viridis tronquée** (bleu-indigo → vert → jaune-vert),
échantillonnée par interpolation linéaire en arithmétique pure. La signature publique
(`rgb_from_value: [(r,g,b: UInt8)]` indexé par `UInt16`) et la courbe gamma sont conservées à
l'identique → `getRGB`, `setPixel`, `setBoldPixel`, `getScaleImage` et les deux vues SwiftUI ne bougent pas,
et la légende suit automatiquement.

Trois bénéfices en un : lisible en deutéranopie (~8 % des hommes), une carte ne se lit plus comme une
panne (déterminant pour la capture n°1), et suppression au passage de 65 536 instanciations de
`SwiftUI.Color` **hors main thread** + un force-unwrap `(c.cgColor?.components)![0]`.

**Effet de bord à traiter** : les overlays posés sur la bande de légende (`Image(systemName: "restart")`
et `Text("… bit/s")`) n'ont pas de `foregroundColor` et prennent `.primary` (noir) — illisible sur le
nouveau bas de bande sombre. Ajouter `.foregroundStyle(.white)` + ombre portée sur les **4 sites** :
`HeatMapSwiftUIView.swift:481-493` et `StepByStepHeatMapView.swift:333-348`.

Contrôle visuel obligatoire sur le plan `plan-bgonly` (le plus clair) et sur l'export partagé
(`SwiftUIViewSharedTools.computeMergedImage`, qui compose le plan en gris à alpha 0,2 par-dessus).

---

## Étape 5 — Réactiver les demandes d'avis

~61 notes pour ~2 500 ventes (2,4 %) : le levier est réel, mais seulement si l'invite tombe au bon moment
(quota Apple : **3 invites max / 365 jours / utilisateur**).

- Nouveau `iOS tools/Tools/ReviewRequester.swift` : politique centralisée (≥ 2 heat maps exportées avec
  succès, 1 invite par version, 90 jours minimum entre deux) + une URL `?action=write-review` pour un
  bouton manuel qui, lui, ne consomme aucun quota.
- **Supprimer** `let disable_request_reviews = true` de `SpeedTest/SNMP/SNMPView.swift:13` — constante
  globale planquée dans un fichier sans rapport, cause racine du problème.
- **Supprimer** les deux `onAppear` mal placés : `Interman3DSwiftUIView.swift:1126-1133` (vue 3D) et
  `TracesSwiftUIView.swift:234-240` (panneau de logs) — ils brûlent des slots sans contrepartie.
- **Câbler sur le succès uniquement** : aujourd'hui `StepByStepSwiftUIView.swift:69` et
  `HeatMapSwiftUIView.swift:104` demandent l'avis même quand l'enregistrement a échoué (« Access to photos
  is forbidden »). Séparer les deux branches, puis déclencher `@Environment(\.requestReview)` (iOS 16+)
  via un flag `@Published` du view model, ~1,2 s après la fermeture de l'alerte UIKit.

⚠️ Impossible à valider en TestFlight (l'invite n'y apparaît jamais) → tester en Debug/simulateur.

---

## Étape 6 — Mode démo + pipeline de captures

**6a. Mode démo `#if DEBUG`** — nouveau `iOS tools/SpeedTest/GUI/HeatMap/DemoData.swift`, activé par
l'argument de lancement `-UIScreenshotMode`. Il injecte ~10 sondes en coordonnées relatives produisant un
dégradé diagonal lisible, fige `max_scale` et la valeur du compteur, et **court-circuite le
`chargenTCP(51.75.31.39)`** : plus aucune dépendance réseau pour obtenir une belle heat map reproductible.
Câblage en 3 points : `StepByStepSwiftUIView.swift:474-491` (onAppear) et
`StepByStepHeatMapView.swift:419` (timer de vitesse).

**6b. `scripts/screenshots.sh`** — build simulateur + `simctl status_bar override` (heure figée à 9:41,
batterie pleine) + lancement avec `-AppleLanguages "(de)"` pour capturer les 4 langues sans changer les
réglages du simulateur, puis capture à la demande via `simctl io screenshot`.

**6c. `scripts/compose-screenshots.swift`** — composition du bandeau texte **en haut** de l'image
(le texte des captures est OCRisé et indexé par Apple depuis 2025, et seul le haut est visible dans la
vignette des résultats), sortie PNG **sans canal alpha** aux formats exigés : **1320 × 2868** (iPhone 6,9")
et **2064 × 2752** (iPad 13"). Script Swift/AppKit plutôt qu'ImageMagick, qui n'est pas installé.
Légendes pilotées par un `scripts/screenshot-captions.tsv` versionné.

**6d. Les 3 captures**, dans cet ordre imposé par le rapport :
1. la heat map **terminée** avec légende courte en haut — « See your WiFi dead zones, room by room » ;
2. l'écran de mesure en cours, « walk & tap » — « Walk, tap, measure — no extra hardware » ;
3. la liste des appareils du réseau — « Every device on your network, in one list ».

Jamais « Network Analyzer PRO 3D edition ». Les captures 2 et 3 sont mieux prises sur appareil réel
(le simulateur ne découvre presque rien sur le réseau), puis rééchantillonnées avec `sips`.

**Approche écartée** : `fastlane snapshot` / target UITest — automatiser un `UISplitViewController` UIKit
imbriquant SceneKit et SwiftUI, sans aucun identifiant d'accessibilité posé, pour 3 captures, n'est pas
rentable et impose une nouvelle target + un `pod install`.

---

## Étape 7 — Allemand dans l'app (`de.lproj`)

Fichiers à créer :
```
iOS tools/de.lproj/Localizable.strings                     ← 166 clés, calquées sur fr.lproj
iOS tools/de.lproj/InfoPlist.strings
iOS tools/SpeedTest/GUI/UIKit/de.lproj/SpeedTest.strings   ← 22 entrées, calquées sur en.lproj
iOS tools/SpeedTest/Settings.bundle/de.lproj/Root.strings  ← 4 entrées, aucun pbxproj à toucher
```
Tous en UTF-8 sans BOM. Enregistrement via Xcode → projet → Info → Localizations → `+` German : Xcode
écrit lui-même `knownRegions` et les deux `PBXVariantGroup` (les enfants d'un variant group n'ont pas
besoin de `PBXBuildFile`, la phase Resources n'est pas touchée).

Trois pièges :
- **Les clés sont le texte anglais** — ne jamais traduire la partie gauche. Contrôle d'intégrité par
  `diff` des clés fr/de.
- **`"parameter-lang" = "en";`** en allemand (et non `"de"`) tant que
  `fenyo.net/network3dwifitools/new-manual.html?lang=de` n'existe pas : 5 boutons d'aide mèneraient à une 404.
- Ne pas prendre `fr.lproj/SpeedTest.strings` comme modèle (3 entrées sur 22 seulement y sont traduites) ;
  partir de `en.lproj`.

**Migration vers un String Catalog `.xcstrings` : écartée pour cette release.** Le projet contient des clés
dynamiques (`NSLocalizedString(Self.messages[model.step], …)` dans `StepByStepHeatMapView.swift:162`,
`NSLocalizedString(description, …)` dans `Model.swift:592-593`) que l'extracteur Xcode ne voit pas : elles
seraient marquées `stale` et un nettoyage automatique casserait des dizaines de traductions **silencieusement**
(fallback = clé anglaise, donc invisible en test). À planifier dans une release dédiée, après refactor.

Au passage, à traiter tant qu'on y est : les chaînes de debug visibles dans l'UI (`Hello, world!`,
`salut`, `TEST add new node`, `test1`) et les `"no IPv4 address"` / `"no IPv6 address"` non localisés
(`MasterViewController.swift`). La désynchronisation fr↔es relevée initialement a été largement résorbée
par le commit `41c7543` — à revérifier par `diff` des clés avant de traduire.

---

## Étape 8 — `fastlane deliver` (sans `snapshot`)

`fastlane/` avec `Appfile`, `Deliverfile`, `metadata/<locale>/{name,subtitle,keywords,description,
release_notes}.txt` et `screenshots/<locale>/*.png`, pour
`en-US, en-GB, fr-FR, es-ES, de-DE, nl-NL, it-IT`. Aucune target à créer. Upload par
`fastlane deliver --skip_binary_upload`.

Bénéfice décisif ici : **les métadonnées des 7 locales deviennent versionnées et diffables dans git**.
Après un effondrement de −84 %, pouvoir répondre à « qu'est-ce qui a changé et quand » vaut à soi seul
l'installation — c'est aussi ce qui manquait pour trancher le décrochage d'avril 2026.

---

## Ordre d'exécution

| # | Étape | Bloquant pour la 6.2 ? |
|---|---|---|
| 0 | Checklist App Store Connect (phase 1) | non — **gain immédiat, à faire tout de suite** |
| 1 | Variantes de nom → arbitrage → textes des 7 locales | non (mais conditionne 2, 6, 8) |
| 2 | Versions + nom + chaînes de permission | **oui** |
| 3 | `InfoPlist.strings` en/fr/es | **oui** (rejet 5.1.1 possible sinon) |
| 4 | Palette heat map + overlays de légende | **oui** (les captures doivent la montrer) |
| 5 | Demandes d'avis | **oui** |
| 6 | Mode démo + captures 6,9" et 13" × 4 langues | **oui** |
| 7 | `de.lproj` | non — peut glisser en 6.3 |
| 8 | `fastlane deliver` | non — mais à faire avant l'upload des métadonnées |

---

## Vérification

- **Build** : `xcodebuild -workspace "iOS tools.xcodeproj.xcworkspace" -scheme "iOS tools" -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" build`
- **Localisations embarquées** : `ls "<DerivedData>/iOS tools.app" | grep lproj` → doit lister `Base en fr es de`
- **Chaînes de permission** : `plutil -p "<DerivedData>/iOS tools.app/fr.lproj/InfoPlist.strings"` et
  `plutil -p "<DerivedData>/iOS tools.app/Info.plist" | grep -E 'Usage|Version|DisplayName'` →
  `CFBundleShortVersionString` doit valoir **6.2** (et non 5.3.0), aucune chaîne de test.
- **Intégrité des traductions** : `diff <(grep -o '^"[^"]*"' fr.lproj/Localizable.strings | sort) <(grep -o '^"[^"]*"' de.lproj/Localizable.strings | sort)` → vide.
- **Palette** : lancer le mode pas-à-pas sur `plan-rectangle` puis sur `plan-bgonly`, vérifier que la bande
  de légende, le curseur et le texte « … bit/s » restent lisibles, puis « Share your map » et contrôler
  l'image exportée dans la pellicule.
- **Avis** : `ReviewRequester.disabled = false` en Debug, exporter 2 heat maps → l'invite doit apparaître
  après la seconde, jamais après une erreur d'enregistrement.
- **Captures** : `sips -g pixelWidth -g pixelHeight` sur chaque PNG produit → exactement 1320×2868 / 2064×2752,
  et `sips -g hasAlpha` → `no`.
- **Métadonnées** : `fastlane deliver --skip_binary_upload --verify_only` avant tout envoi réel.

## Hors périmètre (phases 3 et 4, à traiter ensuite)

Passage en gratuit + déverrouillage unique non consommable (~14,99 €) avec conservation des droits des
acheteurs existants ; RoomPlan/LiDAR pour le plan de sol automatique ; mode « mesure en un geste » ;
passerelle Raccourcis pour le RSSI réel en dBm ; Apple Ads ; pages produit personnalisées.
