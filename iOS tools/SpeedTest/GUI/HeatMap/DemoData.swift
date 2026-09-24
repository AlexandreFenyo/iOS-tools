//
//  DemoData.swift
//  iOS tools
//
//  Mode démo pour les captures d'écran App Store, compilé uniquement en Debug et
//  activé par l'argument de lancement -UIScreenshotMode (cf. scripts/screenshots.sh).
//
//  En mode démo, l'écran de heat map pas-à-pas n'a aucune dépendance réseau : le
//  chargen automatique vers le serveur public n'est pas lancé, un jeu de sondes
//  pré-rempli produit une carte reproductible, et le compteur affiche un débit figé.
//

#if DEBUG
import Foundation

enum DemoMode {
    static let enabled = ProcessInfo.processInfo.arguments.contains("-UIScreenshotMode")

    /// Scénario de capture, passé en argument : -UIScreenshotScenario measure
    ///   "welcome"  : écran d'accueil (interface avancée / pas à pas / documentation)
    ///   "heatmap"  : carte terminée (défaut)
    ///   "measure"  : mesure en cours, carte partielle avec les points de mesure
    ///   "discover" : pas de modal d'accueil, liste des cibles
    ///   "3d"       : vue réseau 3D, mode caméra « 3D », zoom de 20 %
    ///   "traces"   : onglet des traces, journal fictif
    static let scenario: String = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-UIScreenshotScenario"), i + 1 < args.count {
            return args[i + 1]
        }
        return "heatmap"
    }()

    /// Scénarios qui ferment le modal d'accueil au lancement.
    static var skipsWelcome: Bool { ["discover", "3d", "traces"].contains(scenario) }

    /// Scénarios qui naviguent du modal d'accueil vers l'écran de heat map.
    static var opensHeatMap: Bool { ["heatmap", "measure"].contains(scenario) }

    /// Onglet affiché au lancement (0 Exploration, 1 Vue 3D, 2 SNMP, 3 Traces).
    static var initialTab: Int? {
        switch scenario {
        case "3d": return 1
        case "traces": return 3
        default: return nil
        }
    }

    /// Journal fictif de l'onglet Traces : cohérent avec le réseau de démo
    /// (DBMaster.addDefaultNodes), sans aucune donnée réelle. Horodaté à partir de 9:38.
    static let traces: [(seconds: Int, level: LogLevel, text: String)] = [
        (0, .INFO, "main: application launched"),
        (1, .INFO, "Bonjour/mDNS: start browsing multicast DNS / Bonjour services of type _speedtestapp._tcp."),
        (1, .INFO, "Bonjour/mDNS: start browsing multicast DNS / Bonjour services of type _airplay._tcp."),
        (2, .INFO, "Bonjour/mDNS: service found: type:_airplay._tcp.; name:Living Room TV; hostname:Living-Room-TV.local."),
        (2, .DEBUG, "NetServiceDidResolveAddress: adding 192.168.1.45 to Living-Room-TV.local."),
        (3, .INFO, "Bonjour/mDNS: service found: type:_airplay._tcp.; name:HomePod; hostname:HomePod.local."),
        (3, .DEBUG, "NetServiceDidResolveAddress: adding 192.168.1.125 to HomePod.local."),
        (4, .INFO, "Bonjour/mDNS: service found: type:_speedtestapp._tcp.; name:iPad; hostname:iPad.local."),
        (4, .DEBUG, "NetServiceDidResolveAddress: adding 2001:db8:1a2b:10::20 to iPad.local."),
        (5, .INFO, "Bonjour/mDNS: service found: type:_ipp._tcp.; name:printer; hostname:printer.home.arpa."),
        (6, .INFO, "network browsing: start browsing the network"),
        (6, .INFO, "network browsing: sending ICMPv4 broadcast packets"),
        (6, .DEBUG, "network browsing: sending ICMPv4 broadcast packet to 192.168.1.255"),
        (7, .INFO, "network browsing: sending ICMPv6 multicast packets"),
        (7, .DEBUG, "network browsing: sending ICMPv6 multicast packet to ff02::1"),
        (8, .DEBUG, "network browsing: answer from IPv4 address: 192.168.1.1"),
        (8, .DEBUG, "network browsing: answer from IPv4 address: 192.168.1.10"),
        (8, .DEBUG, "network browsing: answer from IPv4 address: 192.168.1.12"),
        (9, .DEBUG, "network browsing: answer from IPv6 address: 2001:db8:1a2b:10::1"),
        (9, .DEBUG, "network browsing: answer from IPv6 address: 2001:db8:1a2b:10::42"),
        (10, .INFO, "network browsing: finished waiting for IPv4 replies"),
        (11, .INFO, "network browsing: finished waiting for IPv6 replies"),
        (12, .INFO, "SNMP: agent found on 192.168.1.1 (udp/161)"),
        (12, .INFO, "SNMP: agent found on 192.168.1.10 (udp/161)"),
        (13, .INFO, "SNMP: agent found on 192.168.1.12 (udp/161)"),
        (14, .INFO, "browsing TCP ports: target 192.168.1.10"),
        (16, .DEBUG, "browsing TCP ports: 192.168.1.10 port 22 open"),
        (17, .DEBUG, "browsing TCP ports: 192.168.1.10 port 445 open"),
        (18, .DEBUG, "browsing TCP ports: 192.168.1.10 port 5000 open"),
        (21, .INFO, "network browsing: finished"),
        (24, .INFO, "ICMP loop: starting for target 192.168.1.1"),
        (25, .DEBUG, "ICMP loop: received answer from 192.168.1.1 after 2.1 ms"),
        (26, .DEBUG, "ICMP loop: received answer from 192.168.1.1 after 1.8 ms"),
        (27, .DEBUG, "ICMP loop: received answer from 192.168.1.1 after 2.4 ms"),
        (28, .INFO, "flood TCP chargen port: starting for target 192.168.1.20"),
        (31, .INFO, "flood TCP chargen port: target 192.168.1.20 - 187.4 Mbit/s"),
        (34, .INFO, "flood TCP chargen port: target 192.168.1.20 - 191.2 Mbit/s"),
        (37, .INFO, "flood TCP chargen port: stopped with target 192.168.1.20"),
    ]

    /// Haut de l'échelle : 240 Mbit/s.
    static let max_scale: Float = 240_000_000

    /// Valeur figée du compteur et du curseur d'échelle.
    static let displayed_speed: Float = 187_400_000

    /// Sondes en coordonnées relatives (0...1) du plan, débit en bit/s.
    /// Disposition choisie pour une lecture immédiate : très bon débit près du
    /// routeur (bas-gauche), affaiblissement progressif vers le coin opposé —
    /// le dégradé traverse toute la rampe de couleurs sans dominer par une teinte.
    private static let probes: [(x: Float, y: Float, v: Float)] = [
        (0.22, 0.82, 232_000_000), (0.52, 0.86, 205_000_000), (0.78, 0.80, 150_000_000),
        (0.18, 0.58, 198_000_000), (0.50, 0.55, 141_000_000), (0.82, 0.52, 74_000_000),
        (0.24, 0.30, 118_000_000), (0.55, 0.26, 62_000_000), (0.80, 0.22, 27_000_000),
        (0.40, 0.10, 41_000_000),
    ]

    /// Convertit les sondes relatives en valeurs absolues pour une image donnée.
    static func values(width: Int, height: Int) -> [IDWValue<Float>] {
        probes.map {
            IDWValue<Float>(x: UInt16($0.x * Float(width)),
                            y: UInt16($0.y * Float(height)),
                            v: $0.v)
        }
    }
}
#endif

#if DEBUG
import UIKit

extension MasterViewController {
    /// Scénario « discover » sur iPad et Mac (où la courbe est visible à côté de la liste) :
    /// reproduit les gestes d'un utilisateur — toucher flood.eowyn.eu.org (ouvre la liste de
    /// ses IP, qui sélectionne une adresse et lance la boucle de ping, donc la courbe), revenir
    /// à la liste des cibles, la remonter tout en haut. Le script de capture attend ensuite que
    /// la courbe occupe toute la largeur du graphique.
    func demoPrepareDiscover() {
        guard DemoMode.enabled, DemoMode.scenario == "discover",
              ProcessInfo.processInfo.isMacCatalystApp || UIDevice.current.userInterfaceIdiom == .pad
        else { return }

        demoSelectFlood(attempt: 0)
    }

    private func demoSelectFlood(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            let flood = Node()
            flood.addDnsName(DomainName(HostPart("flood"), DomainPart("eowyn.eu.org")))
            var target: IndexPath?
            for section in SectionType.allCases {
                if let row = DBMaster.shared.sections[section]?.nodes.firstIndex(where: { $0.isSimilar(with: flood) }) {
                    target = IndexPath(row: row, section: section.rawValue)
                    break
                }
            }
            // La ligne doit exister dans le tableau affiché, pas seulement dans le modèle :
            // sinon selectRow lève une exception (le tableau se remplit après le modèle)
            guard let target,
                  target.section < self.tableView.numberOfSections,
                  target.row < self.tableView.numberOfRows(inSection: target.section)
            else {
                if attempt < 5 { self.demoSelectFlood(attempt: attempt + 1) }
                return
            }
            self.tableView.selectRow(at: target, animated: false, scrollPosition: .none)
            self.tableView(self.tableView, didSelectRowAt: target)
            self.performSegue(withIdentifier: "segue to IP list", sender: self)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self else { return }
                    if let selected = self.tableView.indexPathForSelectedRow {
                        self.tableView.deselectRow(at: selected, animated: false)
                    }
                    self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.adjustedContentInset.top), animated: true)
                }
            }
        }
    }
}
#endif
