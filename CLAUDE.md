# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**WiFi Heat Map & Analyzer** (App Store name; bundle id `net.fenyo.apple.wifi-map-explorer`, formerly "WiFi Map Explorer") — an iOS/iPadOS/Mac-Catalyst network toolbox: LAN discovery (mDNS/Bonjour, DNS, TCP port scan), throughput/latency measurement (chargen/discard/flood/ICMP), an SNMP browser, a 3D network map, and a WiFi heat map overlaid on a floor plan.

~90 % Swift, ~10 % C. UIKit drives the master GUI (storyboard `SpeedTest.storyboard`); SwiftUI is used for the heat map, node details, SNMP and log panels; SpriteKit for the rolling chart; SceneKit for the 3D map.

`/Users/fenyo/git3` is a symlink to `/Volumes/external-mac/fenyo/git3`, so both configured working directories are the same checkout.

## Build & run

CocoaPods (CTHelp) is in use, so the **workspace** is the entry point — note the unusual name (`.xcodeproj.xcworkspace`, not `.xcworkspace`):

```sh
open "iOS tools.xcodeproj.xcworkspace"

# Device build
xcodebuild -workspace "iOS tools.xcodeproj.xcworkspace" -scheme "iOS tools" \
           -destination 'generic/platform=iOS' build -skipMacroValidation

# Simulator build — the simulator slice of libnetsnmp is arm64 only
xcodebuild -workspace "iOS tools.xcodeproj.xcworkspace" -scheme "iOS tools" \
           -configuration Debug -destination "generic/platform=iOS Simulator" \
           ARCHS=arm64 ONLY_ACTIVE_ARCH=NO build

# Mac Catalyst build
xcodebuild -workspace "iOS tools.xcodeproj.xcworkspace" -scheme "iOS tools" \
           -destination 'platform=macOS,variant=Mac Catalyst,arch=arm64' build -skipMacroValidation
```

Always build via `-workspace`, never `-project`: a `-project` build does not build the CTHelp pod, so it fails with `module map file …/CTHelp/CTHelp.modulemap not found` whenever DerivedData is empty. `-skipMacroValidation` is needed because of the `iOSToolsMacros` SPM macro package. Mac build: run on **"My Mac (Mac Catalyst)"**; "Any Mac" is the archiving destination (two archs).

There is **no test target** — `iOS toolsTests/` and `iOS toolsUITests/` contain stub files that are not built. Verification is done by building and running.

Deployment target iOS 16.6, Swift 5 language mode, `SUPPORTS_MACCATALYST = YES`, Designed-for-iPad disabled, device family 1,2.

### Other scripts

- `scripts/screenshots.sh [-l en-US,fr-FR] [-d iphone69,ipad13,ipad13-landscape,mac] [-o dir] [-n]` — App Store screenshots, fully automated via the app's demo mode (see below): builds Debug, creates/reuses dedicated simulators on the newest iOS runtime ("ASC iPhone 6.9" = iPhone 17 Pro Max, 1320×2868; "ASC iPad 13" = iPad Pro 13" M5, 2064×2752 — the only two iOS sizes App Store Connect requires, all others are downscaled by Apple), captures the Mac Catalyst window (demo mode resizes it to 16:10 via `requestGeometryUpdate(.Mac(systemFrame:))`; `scripts/mac-window-id.swift` finds it for `screencapture -l`; output 2880×1800 from a Retina screen, 1440×900 otherwise), checks every capture's pixel size, then runs the compositor. Mac captures need **Screen Recording** permission for the terminal and an **unlocked screen** (the script refuses to run otherwise). iOS captures go through a temp dir: the simulator service cannot write to the external volume holding the repo. `ipad13-landscape` (2752×2064) is a second pass on the same iPad simulator: neither the app (iPadOS refuses `requestGeometryUpdate` orientation changes in its windowed mode, UISceneErrorDomain 101) nor `simctl` can rotate a device, and Accessibility-driven clicks on DeviceHub (Xcode 27's replacement for Simulator.app) are refused on this Mac, so the script runs `scripts/SimRotator` — a standalone xcodegen project (`project.yml`, regenerate with `xcodegen`) whose only UI test sets `XCUIDevice.shared.orientation` from `TEST_RUNNER_SIM_ORIENTATION` (~1 min per rotation, hence two passes rather than one rotation per screen).
- `scripts/compose-screenshots.swift` + `screenshot-captions.tsv` — adds the indexed caption banner, outputs ASC-sized PNGs without alpha.
- `scripts/frise-screenshots.swift` — the **"frise" variant, the one to publish** (owner's choice, 24 Sep 2026): each raw capture is framed in a drawn device (iPhone 17 Pro Max, iPad Pro 13" landscape, MacBook Pro), tilted in perspective with a drop shadow, on a continuous mint background crossed by a seeded network graph, captions in dark text on top; the strip is cut into ASC-sized panels so they scroll as one frise (some devices straddle two panels; iPads overlap in pairs). Output `<locale>/<device>-frise/`. Run by `screenshots.sh` after the compositor; per-device placement tables in `layout()`, tuned for 6 screens.
- `screenshot-captions.tsv` holds 6 screens × 7 store locales (en-US, en-GB, fr-FR, es-ES, de-DE, nl-NL, it); en-GB, nl-NL and it reuse the English UI captures (the app is only localized in en/fr/es/de).
- `generate_oid_dictionary.sh` — regenerates `iOS tools/SpeedTest/SNMP/oid_dictionary.json` from `snmptranslate` (run on a host that has net-snmp installed).
- `countlines.sh` — expects the sibling SPM packages checked out at `../` (`SwiftAdvancedAtomics*Package`, `iOSToolsMacros`, `WebClientsPackage`).
- `export.sh` — publishes an ad-hoc `.ipa` + manifest to fenyo.net.
- `ASO/tools/asc.sh` — App Store Connect API client (needs `ASC_ISSUER_ID` and the `.p8` key in `~/.appstoreconnect/`, never in the repo).

## Architecture

### Model layer — `iOS tools/SpeedTest/Model/Model.swift`

`DBMaster.shared` (`@MainActor`) is the single source of truth: a `Set<Node>` plus known `IPNetwork`s, partitioned into `sections: [SectionType: ModelSection]` (localhost / gateway / iOS devices / other hosts / internet …) that map directly onto the master table view's sections. A `Node` aggregates names (`DomainName`/`FQDN` built from `DomainPart`s), IPv4/IPv6 addresses, TCP/UDP `Port`s and Bonjour service info; it is `Codable` and user-saved nodes are persisted as base64-encoded JSON in `UserDefaults` under the `nodes` key (`saveNode`/`loadNodes`/`unpersistNode`). Mutating `nodes` cascades into `DiscoveredPortsModel.shared`, which feeds the SwiftUI ports view.

Everything UI-facing is `@MainActor`; discovery and measurement run on background tasks/threads that hop back to the main actor to publish results.

### GUI structure

`SplitViewController` (storyboard) → `LeftNavController` (master list: `MasterViewController`, `MasterIPViewController`) and `RightNavController` → `MyTabBarController` with the detail tabs (`DetailViewController`, `IntermanViewController` 3D map, `SnmpViewController`, `TracesViewController` log console, heat map view controllers). UIKit view controllers host SwiftUI views via `UIHostingController`; each SwiftUI screen has a `@MainActor` `…ViewModel.shared` singleton as its bridge (`MapViewModel`, `StepByStepViewModel`, `DetailViewModel`, `TracesViewModel`, `CameraModel`).

`DeviceManager` (protocol declared in `MasterViewController.swift`) is the callback interface that all background workers use to report back: `addNode(...)`, `setInformation(_:)`, `addTrace(_:level:)`. `MasterViewController` implements it. When adding a new scanner/client, take a `DeviceManager` rather than reaching into view controllers.

iOS 26 required workarounds that are easy to break. The storyboard's classic `UISplitViewController` no longer adds its child views to the hierarchy, so on iOS 26+ `AppDelegate` builds a `.doubleColumn` split view controller programmatically and swaps it into the tab bar controller (the legacy `displayModeButtonItem` is also dropped there). An older fix consisted in setting `UIDesignRequiresCompatibility` to YES in `Info.plist` — the comments in `leftNavController.swift` / `RightNavController.swift` still refer to it, but the key is gone and the programmatic split view replaces it. For Liquid Glass, `MyTabBarController` builds an alternate `UITabBar`, and `leftNavController.compensateLiquidGlassPadding()` subtracts the excess padding **dynamically** against the window safe area (an earlier fixed `-45` pushed the bar under the Dynamic Island / Mac window buttons).

### Networking — Swift over C

Low-level socket work lives in C (`Tools/Networks/NetTools.c`, `SpeedTest/Networks/Clients/local{Chargen,Discard,Flood,Ping}Client.c`, `Tools/genericTools.c`) and is exposed through `iOS tools/Tools/iOS tools-Bridging-Header.h`; each C client has a Swift wrapper (`LocalChargenClient.swift`, …) that owns the thread and reports throughput/RTT. `Networks/Servers/` implements the local chargen/discard/app services announced over Bonjour; `Networks/Browsers/` does mDNS, service and TCP-port discovery. `NetTools.c` uses real `route.h` structs on macOS (Catalyst) — the iOS and macOS paths differ there.

`Defaults.swift` holds `service_names`, the Bonjour service list that **must stay in sync with `NSBonjourServices` in `Info.plist`**, otherwise announcements are silently not received.

### SNMP

`SNMPManager` (`SpeedTest/SNMP/SNMPManager.swift`) drives a patched **net-snmp 5.9.4** (sources: github.com/AlexandreFenyo/net-snmp) through custom C entry points declared in the bridging header (`alex_walk`, `alex_translate`, `alex_setsnmpmibdir`, and a rolling buffer `alex_rollingbuf_*` that the Swift side polls from a background thread). Argument vectors are pushed with `alex_set_av*`, mimicking a `snmpwalk` command line — `pushArray` must stay in sync with `alex_walk.c`. 64 MIB files are bundled in `iOS tools/SNMP/mibs/`; `oid_dictionary.json` replaced the former HTTP call to `snmptranslate.cgi`.

Three prebuilt static slices are selected by SDK-conditional `LIBRARY_SEARCH_PATHS` (the specific path must come **before** `$(inherited)`):

| SDK | Path |
|---|---|
| device | `iOS tools/libnetsnmp/` (arm64/arm64e) |
| simulator | `iOS tools/libnetsnmp/simulator/` (arm64 only) |
| Mac Catalyst | `iOS tools/libnetsnmp/maccatalyst/` (arm64 + x86_64) |

Rebuild procedure: `iOS tools/libnetsnmp/simulator/README.md`. In the net-snmp sources, `mib.c` contains ISO-8859 bytes, so `grep` treats it as binary — `grep -a` is mandatory to see the patches. End-to-end test agent: `flood.eowyn.eu.org`, community `public`, v2c.

`SNMPTypes.swift` holds the OID tree (`OIDNode`, `OIDNodeDisplayable`, filtering/collapse state) and `OIDTimeSeries` (sliding-window bitrate computation for interface counters).

### Heat map, chart, 3D

- `SpeedTest/GUI/HeatMap/IDWView.swift` — inverse-distance-weighting interpolation over the floor plan, multithreaded (`NTHREADS`), with a truncated-viridis LUT computed in pure arithmetic (chosen for deuteranopia legibility). `StepByStepHeatMapView` runs the guided capture flow and contains a watchdog that restarts chargen when throughput stalls for 6 s.
- `Tools/Charts/Chart.swift` — the SpriteKit rolling chart; the node hierarchy is documented in the file header comment. `TimeSeries.swift` feeds it.
- `Tools/Interman/Interman3DModel.swift` — `Interman3DModel.shared` owns the SceneKit scene (`Interman 3D Scene.scn`), mapping `Node`s to `B3DHost` objects and animating broadcasts. Catalyst needed explicit SceneKit bridging (`NSValue(scnMatrix4:)`, `SCNMatrix4FromSimd`).
- `Tools/WiFiSignalMonitor.swift` + `Tools/CoreWLANShim.m` — real RSSI/noise/tx-rate on Mac Catalyst, reached through the Objective-C runtime because CoreWLAN's headers are marked unavailable for Catalyst even though the binary ships a macabi slice. iOS has no equivalent API; the badge only appears on Mac.

### Error handling and traces

The `iOSToolsMacros` SPM package provides `#fatalError(...)` and `#saveTrace(...)`. `#fatalError` respects the `Resilient` key in `Info.plist`: when `true` (current setting) the message is printed and stored but execution continues instead of crashing. Prefer these macros over bare `fatalError`. Traces are persisted with Core Data (`Tools/Persistent/ToolsDataModel.xcdatamodeld`, `PersistentTraces.swift`) and shown in the log console.

### Dependencies

Remote SPM packages (all by the same author): `iOSToolsMacros`, `SwiftAdvancedAtomicsSwiftPackage`, `WebClientsPackage`. CocoaPods: `CTHelp` only. Local checkouts of these packages may exist at `../` for line counting.

## Localization

49 locales in the binary (en base + 48, see `knownRegions`; + `Base.lproj` storyboard). Strings live in `iOS tools/<lang>.lproj/Localizable.strings` (~250 keys) and `Localizable.stringsdict` (plural counters `%d IPs` / `%d ports`), `<lang>.lproj/InfoPlist.strings`, `SpeedTest/GUI/UIKit/<lang>.lproj/SpeedTest.strings` (storyboard) and `SpeedTest/Settings.bundle/<lang>.lproj/Root.strings`. Any new user-visible string must be added to every `Localizable.strings` (48 translated files) plus the storyboard strings files. Never build a sentence by concatenating localized fragments: use one key with `%@`/`%d` (`String(format:)`), word order differs across languages. `popUp(title, message, ok)` localizes its three arguments itself. `en.lproj/Localizable.strings` also holds a few overrides that fix typos in English keys.

Traps documented in `ASO/plan-detaille.md` §7 and still valid:

- **The keys are the English text** — never translate the left-hand side. Integrity check: `diff <(grep -o '^"[^"]*"' fr.lproj/Localizable.strings | sort) <(grep -o '^"[^"]*"' de.lproj/Localizable.strings | sort)` must be empty.
- `en.lproj/Localizable.strings` is nearly empty by design; only `parameter-lang` is defined there. That key selects the language of the online manual and **stays `"en"` in `de.lproj`** until `fenyo.net/network3dwifitools/new-manual.html?lang=de` exists, otherwise five help buttons lead to a 404.
- Migration to a `.xcstrings` String Catalog was **deliberately rejected** for this release: dynamic keys (`NSLocalizedString(Self.messages[model.step], …)` in `StepByStepHeatMapView.swift`, `NSLocalizedString(description, …)` in `Model.swift`) are invisible to Xcode's extractor and would be silently marked stale.
- Don't use `fr.lproj/SpeedTest.strings` as a model for a new storyboard translation — only a few of its 22 entries are translated; start from `en.lproj`.

Demo/screenshot mode: launch arguments `-UIScreenshotMode` and `-UIScreenshotScenario welcome|heatmap|measure|discover|details|3d|traces` (`SpeedTest/GUI/HeatMap/DemoData.swift`) make the app navigate itself with canned data and no network dependency: probe values and frozen `max_scale` for the heat map (the `chargenTCP` bootstrap is short-circuited), a fictitious latency curve in the Explorer chart on iPad/Mac (`demoPrepareDiscover`), a canned log in the Traces tab (`DemoMode.traces`; the tab shows the end of the log, so the varied blocks go last); in `details`, the first target (the local node) carries a network audio receiver's names, ports and Bonjour services, is selected; on iPad/Mac the chart gets the fictitious latency curve, on iPhone it is collapsed (`demoPrepareDetails`). `demo_mode` (`Defaults.swift`) follows `-UIScreenshotMode` in Debug: real discovery is ignored by `DBMaster.addNode` and a fictitious home network is shown (`addDefaultNodes`: `home.arpa`, IPv6 `2001:db8::/32`, generic device names — never put real names or prefixes there, the screenshots are public). Always `false` in Release.

## App Store / ASO

An ASO recovery effort is in progress and is the main driver of recent commits. Read `ASO/ETAT-DU-CHANTIER.md` (handover doc, state as of 23 Sep 2026) **before touching store metadata, version numbers, screenshots or the app name** — it is the authoritative status; `ASO/plan-detaille.md` is the original plan (some of it superseded), `ASO/checklist-phase1.md` holds the ASC actions and the tracking journal, and `ASO/Diagnostic ASO & plan d'action.pdf` the underlying diagnosis.

**Current state (25 Sep 2026).** **6.4 / build 29 is live** (approved 25 Sep 2026); **6.4.1 / build 30 was submitted on 25 Sep 2026** (same code, fixes the iPhone "measure" screenshot of en-*/nl-NL/sk; release AFTER_APPROVAL). The publish script takes `ASC_VERSION`, `ASC_BUILD`, `ASC_WHATS_NEW_FILE`. It is the ASO version: store name "WiFi Heat Map & Analyzer", texts from `ASO/metadata/`, **50 store locales** (same set as the owner's other app Captured!), frise screenshots (iPhone 6.9" + iPad 13" landscape, 6 each per locale), and the app itself localized in **49 lproj** (44 languages + en-AU/en-CA/en-GB/es-MX/fr-CA). Published with `ASO/tools/publish-6.4.py` (steps version / texts / screenshots / build / submit, idempotent, network retries). 6.3 (UIScene launch fix, 6.1 store page) is live.

**Context.** App Store id 1662393654. Sales fell ~84 % (≈73 → ≈11 units/month) because impressions collapsed 88 %, not because the page stopped converting. Root cause: the worldwide takedown of March–April 2025 (trademark complaint by the holder of "WiFi Map") reset the ranking capital; the app came back in May 2025 under a new name with no indexed field changed since April 2024.

**Locked decisions.** Store name **"WiFi Heat Map & Analyzer"** in all 7 locales; `CFBundleDisplayName` = "WiFi Heat Map" (short prefix, untruncated under the icon); keywords calibrated in **bytes** with `snmp`/`mib` added; the description must **not** promise PDF export or multi-map history (not implemented); target **6.2 / build 27**, release set to **MANUAL**; Mac ships as native Catalyst under the same bundle id (universal purchase) with real RSSI; screenshots are regenerable and deliberately **not** versioned (`ASO/screenshots*/` is gitignored). **iPad screenshots are published in landscape** (`ipad13-landscape`, 2752×2064: the two-column list/details layout is the real iPad UI), iPhone in portrait, plus the Mac set; one orientation per device set, never mixed (decided 24 Sep 2026).

**Done.** On ASC: version 6.2 created (`PREPARE_FOR_SUBMISSION`), 7 complete locales (en-US, en-GB, fr-FR, es-ES, de-DE, nl-NL, **it**), 42 screenshots uploaded, privacy URL fixed, promotional text and 6 review replies updated on the shipping 6.1. In code: viridis heat-map palette, `ReviewRequester`, the HKG chargen-stall watchdog, `Info.plist` cleanup, full German localization, demo/screenshot mode, the three net-snmp slices, Catalyst support and the CoreWLAN RSSI badge, dynamic Liquid Glass safe-area compensation.

**Remaining, in order.** (1) German native proofreading of `ASO/metadata/de-DE/` and `de.lproj`. (2) Manual testing of the Mac build — end-to-end heat map including photo save under sandbox, SNMP walk, long ICMP ping. (3) Owner tasks: open an Apple Ads account for the search-terms report, review the crash organizer for the weeks of 22 Jun and 3 Aug 2026 (likely a crash loop on 1–2 devices; fix in 6.2 if simple). (4) Mention the Mac version and "real dBm on Mac" in descriptions/release notes. (5) Archive and upload **via Xcode, not Transporter** (known signing issue); iOS and Mac are two archives on the same record. (6) Submit — two-step (submit *then* confirm), and publish explicitly since the release is manual. (7) Align fenyo.net afterwards. (8) Phase 3 (free + one-time ~€14.99 unlock with existing buyers exempted via receipt check, RoomPlan/LiDAR, RSSI-sourced heat map on Mac) then phase 4 (Apple Ads on "wifi heatmap"/"wifi dead zone", custom product pages). (9) Log the metrics in `checklist-phase1.md` every two weeks — 90-day goal: impressions 2 886 → 8 000.

**Tooling.** `ASO/tools/asc.sh` + `asc_jwt.rb` talk to the App Store Connect API: `ASC_ISSUER_ID=<issuer> ./asc.sh GET|POST|PATCH|DELETE "/v1/..." [payload.json]`. The App Manager `.p8` key lives in `~/.appstoreconnect/` or `~/.appstore/` (`AuthKey_8534RFTT7P.p8`, both are searched) and must **never** enter the repo. Useful ids, the listing-copy script `prepare-6.3.py` and the API submission sequence are in `ASO/tools/README.md`. Binary upload: `xcodebuild -exportArchive` (`destination=upload`) works only with the Apple account signed in to Xcode — the App Manager key cannot do cloud signing and there is no local distribution certificate. Metadata masters are plain text under `ASO/metadata/<locale>/{name,subtitle,keywords,description,promotional_text,release_notes}.txt` — edit those, then PATCH them up. `fastlane` was planned in `plan-detaille.md` §8 but never adopted; the direct API route replaced it, so there is no `fastlane/` directory.

**Pitfalls that cost time to rediscover.**

- The Italian locale code is **`it`**, not `it-IT`. Keyword fields are 100 **bytes** — accented characters cost 2. No duplicate terms across name / subtitle / keywords.
- Creating an AppInfo localization automatically creates the matching version localization → PATCH afterwards, don't POST.
- ASC localizations are independent of the binary: the 100 keyword bytes per locale are gainable without a new build. Only the "Languages" list on the page derives from the `.lproj` folders.
- Versions come from `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` referenced as `$(...)` in `Info.plist`; `GENERATE_INFOPLIST_FILE` is off, so `Info.plist` is the only source of truth and **`agvtool` must not be used**.
- Review prompts never appear in TestFlight — test them in Debug on the simulator.
- Contracts expire **7 Oct 2026**; the free-apps contract is the prerequisite for phase 3a.
- `asc.sh` pre-resolves the API host by hand because running simulators can disturb `mDNSResponder`.

## Conventions

Comments and internal documentation are a mix of French and English; recent work is mostly in French. Commit messages follow the same pattern. `iOS tools/GUI.md` and `iOS tools/Models.md` are the author's working notes (protocol captures, data-model sketches), not maintained specifications.
