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
    /// Assez long (~135 lignes) pour remplir l'écran d'un iPad 13" ou d'une fenêtre Mac.
    static let traces: [(seconds: Int, level: LogLevel, text: String)] = traces_head + traces_tail

    private static let traces_head: [(seconds: Int, level: LogLevel, text: String)] = [
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

    /// Suite du journal, générée : boucles ICMP, débit, balayage de ports, parcours SNMP.
    /// L'onglet affiche la fin du journal : les blocs les plus variés sont donc en dernier.
    private static let traces_tail: [(seconds: Int, level: LogLevel, text: String)] = {
        var arr = [(seconds: Int, level: LogLevel, text: String)]()
        var t = 40

        t += 3
        arr.append((t, .INFO, "ICMP loop: starting for target 192.168.1.10"))
        let rtts = [1.9, 2.3, 1.7, 2.0, 2.8, 1.8, 2.1, 1.6, 2.4, 1.9, 3.2, 2.0, 1.8, 2.2, 1.7, 2.5]
        for i in 0..<30 {
            t += 1
            arr.append((t, .DEBUG, "ICMP loop: received answer from 192.168.1.10 after \(rtts[i % rtts.count]) ms"))
        }
        t += 1
        arr.append((t, .INFO, "ICMP loop: stopped with target 192.168.1.10"))

        t += 2
        arr.append((t, .INFO, "flood TCP discard port: starting for target 192.168.1.10"))
        for v in [412.6, 437.9, 441.3, 428.0, 445.7, 439.2, 443.8, 436.5] {
            t += 3
            arr.append((t, .INFO, "flood TCP discard port: target 192.168.1.10 - \(v) Mbit/s"))
        }
        t += 1
        arr.append((t, .INFO, "flood TCP discard port: stopped with target 192.168.1.10"))

        t += 2
        arr.append((t, .INFO, "ICMP loop: starting for target 2001:db8:1a2b:10::1"))
        for i in 0..<12 {
            t += 1
            arr.append((t, .DEBUG, "ICMP loop: received answer from 2001:db8:1a2b:10::1 after \(rtts[(i + 5) % rtts.count]) ms"))
        }
        t += 1
        arr.append((t, .INFO, "ICMP loop: stopped with target 2001:db8:1a2b:10::1"))

        t += 3
        arr.append((t, .INFO, "browsing TCP ports: target 192.168.1.12"))
        for port in [80, 443, 515, 631, 9100] {
            t += 1
            arr.append((t, .DEBUG, "browsing TCP ports: 192.168.1.12 port \(port) open"))
        }
        t += 2
        arr.append((t, .INFO, "browsing TCP ports: target 192.168.1.1"))
        for port in [22, 53, 80, 443, 1900, 5000] {
            t += 1
            arr.append((t, .DEBUG, "browsing TCP ports: 192.168.1.1 port \(port) open"))
        }
        t += 2
        arr.append((t, .INFO, "browsing TCP ports: finished"))

        t += 3
        arr.append((t, .INFO, "SNMP: walk started on 192.168.1.1 (v2c, community public)"))
        let snmp = [
            "SNMPv2-MIB::sysDescr.0 = STRING: Home router, firmware 4.2.1",
            "SNMPv2-MIB::sysObjectID.0 = OID: SNMPv2-SMI::enterprises.8072.3.2.10",
            "DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (86412300) 10 days, 0:02:03.00",
            "SNMPv2-MIB::sysContact.0 = STRING: admin@home.arpa",
            "SNMPv2-MIB::sysName.0 = STRING: router.home.arpa",
            "SNMPv2-MIB::sysLocation.0 = STRING: living room",
            "IF-MIB::ifNumber.0 = INTEGER: 4",
            "IF-MIB::ifDescr.1 = STRING: lo",
            "IF-MIB::ifDescr.2 = STRING: eth0",
            "IF-MIB::ifDescr.3 = STRING: wlan0",
            "IF-MIB::ifDescr.4 = STRING: wlan1",
            "IF-MIB::ifType.2 = INTEGER: ethernetCsmacd(6)",
            "IF-MIB::ifType.3 = INTEGER: ieee80211(71)",
            "IF-MIB::ifType.4 = INTEGER: ieee80211(71)",
            "IF-MIB::ifSpeed.2 = Gauge32: 1000000000",
            "IF-MIB::ifSpeed.3 = Gauge32: 866700000",
            "IF-MIB::ifSpeed.4 = Gauge32: 300000000",
            "IF-MIB::ifOperStatus.2 = INTEGER: up(1)",
            "IF-MIB::ifOperStatus.3 = INTEGER: up(1)",
            "IF-MIB::ifOperStatus.4 = INTEGER: up(1)",
            "IF-MIB::ifInOctets.2 = Counter32: 3867240519",
            "IF-MIB::ifInOctets.3 = Counter32: 1204877312",
            "IF-MIB::ifOutOctets.2 = Counter32: 902331876",
            "IF-MIB::ifOutOctets.3 = Counter32: 2789013457",
            "IP-MIB::ipAdEntAddr.192.168.1.1 = IpAddress: 192.168.1.1",
            "IP-MIB::ipAdEntNetMask.192.168.1.1 = IpAddress: 255.255.255.0",
        ]
        for (i, line) in snmp.enumerated() {
            if i % 4 == 0 { t += 1 }
            arr.append((t, .DEBUG, "SNMP: " + line))
        }
        t += 1
        arr.append((t, .INFO, "SNMP: walk finished on 192.168.1.1, \(snmp.count) values"))
        return arr
    }()

    /// Latences fictives de la courbe de l'écran Exploration (iPad, Mac), en µs :
    /// ~8 ms avec un bruit léger et quelques pointes, reproductibles d'une capture à l'autre.
    @MainActor final class DemoRTT {
        private var state: UInt32 = 12345
        private var n = 0

        func next() -> Float {
            state = state &* 1103515245 &+ 12345
            let noise = Float((state >> 16) & 0x7fff) / Float(0x7fff) - 0.5
            n += 1
            let spike: Float = n % 37 == 0 ? 4_500 : (n % 23 == 0 ? 2_000 : 0)
            return 8_000 + 900 * noise + 400 * sin(Float(n) / 9) + spike
        }
    }

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
    /// la courbe de latence est remplie d'emblée par des données fictives — les 3 dernières
    /// minutes, soit plus que la largeur du graphique — puis prolongée d'un point par seconde.
    /// Aucune dépendance réseau, et la capture n'a pas à attendre que la courbe se déroule.
    func demoPrepareDiscover() {
        guard DemoMode.enabled, DemoMode.scenario == "discover",
              ProcessInfo.processInfo.isMacCatalystApp || UIDevice.current.userInterfaceIdiom == .pad
        else { return }

        demoFeedChart(attempt: 0)
    }

    private func demoFeedChart(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            guard let ts = self.detail_view_controller?.ts else {
                if attempt < 10 { self.demoFeedChart(attempt: attempt + 1) }
                return
            }
            let rtt = DemoMode.DemoRTT()
            Task { @MainActor in
                ts.setUnits(units: .RTT)
                await ts.removeAll()
                let now = Date()
                for i in stride(from: 180, to: 0, by: -1) {
                    await ts.add(TimeSeriesElement(date: now.addingTimeInterval(-TimeInterval(i)), value: rtt.next()))
                }
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    Task { @MainActor in
                        await ts.add(TimeSeriesElement(date: Date(), value: rtt.next()))
                    }
                }
            }
        }
    }
}
#endif
