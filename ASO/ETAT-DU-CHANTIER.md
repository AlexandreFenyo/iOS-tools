# Chantier de redressement ASO — état au 18 août 2026

Document de reprise : tout ce qui a été décidé, fait et reste à faire, pour continuer
depuis n'importe quelle machine. Contexte complet dans `Diagnostic ASO & plan d'action.pdf`
(diagnostic du 15 août 2026 : ventes −84 %, cause racine = retrait App Store mars–avril 2025
sur plainte du titulaire de la marque « WiFi Map », aucun champ indexé modifié depuis).

## Décisions actées

| Sujet | Décision |
|---|---|
| Nom App Store | **« WiFi Heat Map & Analyzer »** (identique dans les 7 locales). « Heat Map » en deux mots = 3 jetons indexés. « analyzer » gardé dans le nom mais jugé ingagnable en tête de requête (concurrents à 6 000–115 000 notes) : le pari se joue sur « heatmap » et « dead zone », créneaux quasi vides. |
| Nom sous l'icône | `CFBundleDisplayName` = « WiFi Heat Map » (préfixe court, non tronqué) |
| Sous-titres | en-US « Dead zones, signal & speed » · fr « Zones blanches, signal, débit » · de « Funklöcher, Signal & Speed » · en-GB « Blackspots, signal & speed » (termes différents de l'US = couverture élargie) |
| Mots-clés | calibrés en **octets** (accents = 2 o). `snmp` et `mib` ajoutés (niche vide : un MIB browser payant 6,99 $ survit avec 8 notes). Zéro doublon nom/sous-titre/mots-clés. |
| Description | ne PAS promettre l'export PDF ni l'historique multi-cartes (le PDF §8 les promettait à tort — non implémentés). Section SNMP ajoutée (v1/v2c/v3, 64 MIB). Section « BEFORE YOU BUY » conservée. |
| Version | 6.2 / build 27, publication **MANUAL** (les précédentes étaient AFTER_APPROVAL) |
| Mac | version **Catalyst native** (même bundle id → achat universel iPhone/iPad/Mac), avec **RSSI réel** via CoreWLAN — argument que personne ne peut afficher sur iOS |
| Captures | mode démo compilé Debug (`-UIScreenshotMode`), pipeline scripté, PAS de captures sous git (régénérables) |

## Fait — App Store Connect (via l'API, outillage dans `tools/`)

- **Version 6.2 créée** (`PREPARE_FOR_SUBMISSION`). Ids : version `ec7c637d-919d-4ae4-a12d-c6fea96fd17b`, appInfo éditable `2b4c5325-7066-449b-9db4-99341283f2c6`.
- **7 vitrines complètes** : en-US, en-GB, fr-FR, es-ES, de-DE, nl-NL, it (⚠ code « it », pas « it-IT »). Nom, sous-titre, mots-clés, description, promo, nouveautés — textes maîtres dans `metadata/<locale>/`.
- **42 captures uploadées** sur la 6.2 (7 locales × 3 écrans × iPhone 6,9" 1320×2868 + iPad 13" 2064×2752), toutes `COMPLETE`. Les captures de-DE utilisent l'interface allemande réelle.
- **URL de confidentialité** corrigée : `https://fenyo.net/network3dwifitools/support.html` (pointait vers wifimapexplorer.com, la marque contestée, en http).
- **Sur la 6.1 en vente** (seuls changements publics) : texte promotionnel remplacé (×3 langues, il contenait une note de version) ; **6 réponses aux avis** créées/réécrites — plus aucune ne cite « WiFi Map Explorer »/wifimapexplorer.com, les 13 avis ≤3★ ont tous une réponse.
- **Vérifié le 17/08** : contrats = conditions standard (pas de Tier 1 DMA, la découverte UE fonctionne). DAC7 renseigné par Alexandre le 17/08. ⚠ Contrats expirent le **07/10/2026**. Le contrat « apps gratuites » (actif 05/08/2026) est le prérequis de la phase 3a.
- Sauvegarde des anciennes captures 6.1 : retéléchargeable par API (`GET .../appScreenshotSets?include=appScreenshots` → `templateUrl`) ; une copie locale existait dans `screenshots-backup-6.1/` (non versionnée).

## Fait — code (branche master)

- **Palette heatmap** : viridis tronqué, lisible en deutéranopie, LUT en arithmétique pure (`IDWView.swift`) ; overlays de légende blanc + ombre.
- **Avis** : `Tools/ReviewRequester.swift` (invite après 2 heat maps réussies, 1/version, 90 j min) ; `disable_request_reviews` supprimée ; les 2 `onAppear` gaspilleurs supprimés ; URL manuelle `?action=write-review` dispo.
- **Bug HKG corrigé** : watchdog dans `StepByStepHeatMapView` — relance auto du chargen si débit à 0 pendant 6 s (3 essais max).
- **`Info.plist`** : « ceci est uyn test » remplacé, versions via `$(MARKETING_VERSION)`/`$(CURRENT_PROJECT_VERSION)`, catégorie utilities, armv7 retiré. `InfoPlist.strings` en/fr/es/de (permissions localisées).
- **`de.lproj` complet** : 188 clés + storyboard + Settings.bundle. ⚠ `parameter-lang` = « en » tant que le manuel n'existe pas en allemand. **Relecture germanophone requise avant soumission** (fiche `metadata/de-DE/` + de.lproj).
- **Mode démo captures** : `DemoData.swift`, arguments `-UIScreenshotMode` + `-UIScreenshotScenario heatmap|measure|discover`, navigation auto, aucune dépendance réseau.
- **net-snmp 3 tranches** depuis les sources patchées (github.com/AlexandreFenyo/net-snmp) : appareil (`libnetsnmp/`), simulateur (`libnetsnmp/simulator/`), **Catalyst universelle arm64+x86_64** (`libnetsnmp/maccatalyst/`) — sélection par `LIBRARY_SEARCH_PATHS[sdk=...]`, chemin spécifique AVANT `$(inherited)`. Procédures dans `libnetsnmp/simulator/README.md`. ⚠ `mib.c` contient de l'ISO-8859 : `grep -a` obligatoire.
- **Catalyst** : `SUPPORTS_MACCATALYST=YES`, Designed-for-iPad désactivé, entitlements sandbox dédiés (`iOS tools maccatalyst.entitlements`). Pontages SceneKit explicites (NSValue(scnMatrix4:), `SCNMatrix4FromSimd`). `NetTools.c` : vraies structs route.h sur macOS.
- **RSSI réel sur Mac** : `Tools/CoreWLANShim.m` (sélecteurs publics CWWiFiClient via runtime ObjC — les en-têtes se déclarent indisponibles sous Catalyst alors que le binaire expose macabi ; risque App Review faible mais non nul) + `Tools/WiFiSignalMonitor.swift` + badge `RSSIBadge` dans l'écran heat map. Testé : −61 dBm / −95 dBm / 390 Mbit/s.
- **Safe areas** : compensation Liquid Glass dynamique (`leftNavController.swift`) au lieu du −45 fixe qui faisait passer la barre sous la Dynamic Island / les boutons de fenêtre Mac.

## Outillage (tout dans le dépôt)

- `tools/asc.sh` + `tools/asc_jwt.rb` : client API ASC. Clé `.p8` (App Manager) dans `~/.appstoreconnect/AuthKey_8534RFTT7P.p8` — **à copier sur la nouvelle machine, jamais dans le dépôt**. Issuer ID : voir ASC → Utilisateurs et accès → Intégrations.
- `scripts/screenshots.sh` : captures auto (simulateurs, barre d'état 9:41, langues en/en-GB/fr/es/de × 3 scénarios × iPhone 6,9"/iPad 13"). ⚠ noms de simulateurs à adapter (ici « iPhone 17 Pro Max », « iPad Pro 13-inch (M5) »).
- `scripts/compose-screenshots.swift` + `scripts/screenshot-captions.tsv` : bandeau texte indexé en haut, PNG sans alpha aux formats ASC.
- Test SNMP de bout en bout : `flood.eowyn.eu.org`, communauté `public`, v2c.

## Reste à faire (dans l'ordre)

1. **Relecture germanophone** de `metadata/de-DE/` et `de.lproj` (Funkloch, Ausleuchtung… à valider par un natif).
2. **Tests manuels de la version Mac** : heat map de bout en bout (mesure + sauvegarde photo, sandbox !), walk SNMP, ping ICMP longue durée.
3. **Alexandre** : compte Apple Ads (gratuit, rapport de termes de recherche — seule source fiable de volumes) ; Organizer Xcode → crashs semaines 22/06 et 03/08 (probable boucle de crash 1-2 appareils, correctif à embarquer en 6.2 si simple).
4. **Métadonnées à enrichir avant soumission** : mention de la version Mac + « real dBm on Mac » dans descriptions/nouveautés ; envisager des captures Mac (facultatives).
5. **Archive + upload** : via Xcode (PAS Transporter — problème de signature connu, cf. notes), sauvegarder l'archive pour les symboles. iOS et Mac = deux archives sur la même fiche.
6. **Soumission** : piège du double clic (soumettre PUIS confirmer ; un mail de confirmation fait foi). Release MANUAL : publier explicitement après approbation.
7. **Après publication** : site fenyo.net à aligner (nom, badge App Store) ; réponse HKG déjà en ligne dit « the upcoming 6.2 update ».
8. **Phase 3** (change la trajectoire) : gratuit + déverrouillage unique ~14,99 € (acheteurs existants exemptés — vérif de reçu), RoomPlan/LiDAR, heatmap RSSI sur Mac (source de mesure, pas seulement affichage). **Phase 4** : Apple Ads « wifi heatmap »/« wifi dead zone » (PAS « network analyser »), Reddit, WLAN Professionals, YouTube, pages produit personnalisées (70 dispo, 0 utilisée — une dédiée « pros réseau/SNMP » serait pertinente).
9. **Journal de bord** (`checklist-phase1.md`, dernière section) : relever les indicateurs toutes les 2 semaines. Objectif 90 j : impressions 2 886 → 8 000.

## Pièges connus (coûteux à redécouvrir)

- Locale italienne = « it » ; champs mots-clés = 100 **octets** ; les localisations ASC sont indépendantes du binaire.
- La création d'une localisation AppInfo crée automatiquement la localisation de version (PATCH ensuite, pas POST).
- `agvtool`/Xcode : seul `Info.plist` fait foi (GENERATE_INFOPLIST_FILE absent) — d'où les versions en `$(...)`.
- Demandes d'avis : jamais visibles en TestFlight ; tester en Debug/simulateur.
- « Any Mac » = destination d'archivage (2 archs) — exécuter sur « My Mac (Mac Catalyst) ».
- En cas de DNS système capricieux (mDNSResponder perturbé par les simulateurs) : `asc.sh` fait une pré-résolution automatique.
