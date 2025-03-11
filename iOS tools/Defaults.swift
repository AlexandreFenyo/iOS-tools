//
//  Defaults.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 30/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import SpriteKit
import iOSToolsMacros

// A mode to make screenshots
let demo_mode = false

// This list must be synchronized with the services declared in Info.plist, in order to have authorization to listen to the corresponding service announcements
let service_names = [
    "_speedtestapp._tcp.",
    "_speedtestchargen._tcp.",
    "_speedtestdiscard._tcp.",
    "_1password4._tcp.",
    "_KeynoteControl._tcp.",
    "_acp-sync._tcp.",
    "_adisk._tcp.",
    "_afpovertcp._tcp.",
    "_airdroid._tcp.",
    "_airdrop._tcp.",
    "_airplay._tcp.",
    "_airport._tcp.",
    "_amzn-wplay._tcp.",
    "_androidtvremote._tcp.",
    "_apple-mobdev._tcp.",
    "_apple-mobdev2._tcp.",
    "_apple-sasl._tcp.",
    "_appletv-v2._tcp.",
    "_arduino._tcp.",
    "_atc._tcp.",
    "_bcbonjour._tcp.",
    "_bowtie._tcp.",
    "_bttouch._tcp.",
    "_bttremote._tcp.",
    "_bp2p._tcp.",
    "_cloud._tcp.",
    "_companion-link._tcp.",
    "_coremediamgr._tcp.",
    "_csco-sb._tcp.",
    "_daap._tcp.",
    "_device-info._tcp.",
    "_dhnap._tcp.",
    "_distcc._tcp.",
    "_dns-sd._tcp.",
    "_dpap._tcp.",
    "_duet_air._tcp.",
    "_eppc._tcp.",
    "_esdevice._tcp.",
    "_esfileshare._tcp.",
    "_fax-ipp._tcp.",
    "_ewelink._tcp.",
    "_ftp._tcp.",
    "_gamecenter._tcp.",
    "_googlecast._tcp.",
    "_googlezone._tcp.",
    "_hap._tcp.",
    "_home-sharing._tcp.",
    "_homekit._tcp.",
    "_http._tcp.",
    "_https._tcp.",
    "_http-alt._tcp.",
    "_hudson._tcp.",
    "_hue._tcp.",
    "_ica-networking._tcp.",
    "_ichat._tcp.",
    "_ipp._tcp.",
    "_ipps._tcp.",
    "_ippusb._tcp.",
    "_jenkins._tcp.",
    "_keynotepair._tcp.",
    "_mamp._tcp.",
    "_mediaremotetv._tcp.",
    "_ndi._tcp.",
    "_meshcop._udp.",
    "_net-assistant._tcp.",
    "_nfs._tcp.",
    "_nmea-0183._tcp.",
    "_nvstream._tcp.",
    "_od-master._tcp.",
    "_odisk._tcp.",
    "_omnistate._tcp.",
    "_pdl-datastream._tcp.",
    "_pgpkey-hkp._tcp.",
    "_photoshopserver._tcp.",
    "_physicalweb._tcp.",
    "_presence._tcp.",
    "_printer._tcp.",
    "_privet._tcp.",
    "_psia._tcp.",
    "_ptp._tcp.",
    "_pulse-server._tcp.",
    "_pulse-sink._tcp.",
    "_pulse-source._tcp.",
    "_raop._tcp.",
    "_rdlink._tcp.",
    "_readynas._tcp.",
    "_rfb._tcp.",
    "_riousbprint._tcp.",
    "_rsp._tcp.",
    "_sane-port._tcp.",
    "_scan-target._tcp.",
    "_scanner._tcp.",
    "_sengled._udp.",
    "_servermgr._tcp.",
    "_sftp-ssh._tcp.",
    "_sketchmirror._tcp.",
    "_sleep-proxy._udp.",
    "_smb._tcp.",
    "_spotify-connect._tcp.",
    "_ssh._tcp.",
    "_teamviewer._tcp.",
    "_telnet._tcp.",
    "_tftp._tcp.",
    "_tivo-videos._tcp.",
    "_touch-able._tcp.",
    "_tunnel._tcp.",
    "_udisks-ssh._tcp.",
    "_uscan._tcp.",
    "_uscans._tcp.",
    "_viziocast._tcp.",
    "_webdav._tcp.",
    "_webdavs._tcp.",
    "_wirecastgodirect._tcp.",
    "_withings-aura-bridge._tcp.",
    "_workstation._tcp.",
    "_xserveraid._tcp."
]

// When adding a new service into this array, also add this service to:
// - the service_names array
// - the file named Info.plist
// - the file named tcpports.txt
var service_names_descr: [String : String] = {
    var service_names_descr = [String : String]()
    service_names_descr["_speedtestapp._tcp."] = "Network3DWiFiTools discovering service"
    service_names_descr["_speedtestchargen._tcp."] = "Network3DWiFiTools chargen service"
    service_names_descr["_speedtestdiscard._tcp."] = "Network3DWiFiTools discard service"
    service_names_descr["_1password4._tcp."] = "1Password Wi-Fi Sync"
    service_names_descr["_KeynoteControl._tcp."] = "OSX Keynote"
    service_names_descr["_acp-sync._tcp."] = "Airport Base Station Sync"
    service_names_descr["_adisk._tcp."] = "Automatic Disk Discovery / Time Capsule Backups"
    service_names_descr["_afpovertcp._tcp."] = "AppleTalk Filing Protocol (AFP)"
    service_names_descr["_airdroid._tcp."] = "AirDroid App"
    service_names_descr["_airdrop._tcp."] = "Apple AirDrop"
    service_names_descr["_airplay._tcp."] = "Apple TV"
    service_names_descr["_airport._tcp."] = "AirPort Base Station"
    service_names_descr["_amzn-wplay._tcp."] = "Amazon Devices"
    service_names_descr["_androidtvremote._tcp."] = "Nvidia Shield / Android TV"
    service_names_descr["_apple-mobdev._tcp."] = "OSX Wi-Fi Sync"
    service_names_descr["_apple-mobdev2._tcp."] = "OSX Wi-Fi Sync"
    service_names_descr["_apple-sasl._tcp."] = "Apple Password Server"
    service_names_descr["_appletv-v2._tcp."] = "Apple TV Home Sharing"
    service_names_descr["_arduino._tcp."] = "Arduino"
    service_names_descr["_atc._tcp."] = "Apple Shared iTunes Library"
    service_names_descr["_bcbonjour._tcp."] = "Sketch App"
    service_names_descr["_bowtie._tcp."] = "Bowtie Remote"
    service_names_descr["_bttouch._tcp."] = "Bowtie Remote"
    service_names_descr["_bttremote._tcp."] = "Bowtie Remote"
    service_names_descr["_cloud._tcp."] = "Cloud by Daplie"
    service_names_descr["_companion-link._tcp."] = "Airplay 2"
    service_names_descr["_coremediamgr._tcp."] = "Air Video HD"
    service_names_descr["_csco-sb._tcp."] = "Cisco SB (small business), router/switches"
    service_names_descr["_daap._tcp."] = "Digital Audio Access Protocol (DAAP)"
    service_names_descr["_device-info._tcp."] = "OSX Device Info"
    service_names_descr["_distcc._tcp."] = "Distributed Compiler"
    service_names_descr["_dns-sd._udp."] = "DNS Service Discovery"
    service_names_descr["_dpap._tcp."] = "Digital Photo Access Protocol (DPAP)"
    service_names_descr["_duet_air._tcp."] = "Duet Screen Sharing"
    service_names_descr["_eppc._tcp."] = "Remote Apple Events"
    service_names_descr["_esdevice._tcp."] = "ES File Share App"
    service_names_descr["_esfileshare._tcp."] = "ES File Share App"
    service_names_descr["_fax-ipp._tcp."] = "FAX Printing"
    service_names_descr["_ftp._tcp."] = "File Transfer Protocol (FTP)"
    service_names_descr["_gamecenter._tcp."] = "Apple Game Center"
    service_names_descr["_googlecast._tcp."] = "Google Cast (Chromecast)"
    service_names_descr["_googlezone._tcp."] = "Google Zone (Chromecast)"
    service_names_descr["_hap._tcp."] = "Apple HomeKit – HomeKit Accessory Protocol"
    service_names_descr["_home-sharing._tcp."] = "iTunes Home Sharing"
    service_names_descr["_homekit._tcp."] = "Apple HomeKit"
    service_names_descr["_http-alt._tcp."] = "HTTP server on alternative port"
    service_names_descr["_http._tcp."] = "Hypertext Transfer Protocol (HTTP)"
    service_names_descr["_https._tcp."] = "Hypertext Transfer Protocol (HTTP)"
    service_names_descr["_hudson._tcp."] = "Jenkins App"
    service_names_descr["_hue._tcp."] = "Philips Hue"
    service_names_descr["_ica-networking._tcp."] = "Image Capture Sharing"
    service_names_descr["_ichat._tcp."] = "iChat Instant Messaging Protocol"
    service_names_descr["_ipp._tcp."] = "IPP Printers"
    service_names_descr["_ipps._tcp."] = "IPP Printers"
    service_names_descr["_ippusb._tcp."] = "IPP Printers"
    service_names_descr["_jenkins._tcp."] = "Jenkins App"
    service_names_descr["_keynotepair._tcp."] = "OSX Keynote"
    service_names_descr["_mamp._tcp."] = "MAMP Development Server"
    service_names_descr["_mediaremotetv._tcp."] = "Apple TV Media Remote"
    service_names_descr["_ndi._tcp."] = "Siena TV"
    service_names_descr["_net-assistant._tcp."] = "Apple Remote Desktop"
    service_names_descr["_nfs._tcp."] = "Network File System (NFS)"
    service_names_descr["_nmea-0183._tcp."] = "Navico Multifunctional Displays"
    service_names_descr["_nvstream._tcp."] = "NVIDIA Shield Game Streaming"
    service_names_descr["_od-master._tcp."] = "OpenDirectory Master"
    service_names_descr["_odisk._tcp."] = "Apple Optical Disk Sharing"
    service_names_descr["_omnistate._tcp."] = "OmniGroup (OmniGraffle and other apps)"
    service_names_descr["_pdl-datastream._tcp."] = "PDL Data Stream (Port 9100)"
    service_names_descr["_photoshopserver._tcp."] = "Adobe Photoshop Nav"
    service_names_descr["_physicalweb._tcp."] = "Physical Web, Google"
    service_names_descr["_presence._tcp."] = "iChat Buddies, Apple"
    service_names_descr["_printer._tcp."] = "Printers - Line Printer Daemon (LPD/LPR)"
    service_names_descr["_privet._tcp."] = "Cloud Device Local Discovery API used by cloud services"
    service_names_descr["_psia._tcp."] = "Stretch PSIA IP Camera"
    service_names_descr["_ptp._tcp."] = "Picture Transfer Protocol"
    service_names_descr["_pulse-server._tcp."] = "Pulse Audio Server"
    service_names_descr["_pulse-sink._tcp."] = "Pulse Audio"
    service_names_descr["_pulse-source._tcp."] = "Pulse Audio"
    service_names_descr["_raop._tcp."] = "AirPlay – Remote Audio Output Protocol"
    service_names_descr["_rdlink._tcp."] = "Apple"
    service_names_descr["_readynas._tcp."] = "Netgear Ready NAS"
    service_names_descr["_rfb._tcp."] = "Remote Frame Buffer / Screen Sharing"
    service_names_descr["_riousbprint._tcp."] = "Remote USB port emulation, Printing, Apple"
    service_names_descr["_rsp._tcp."] = "Roku Server Protocol"
    service_names_descr["_samsungmsf._tcp."] = "Samsung"
    service_names_descr["_sane-port._tcp."] = "SANE (Scanner Access Now Easy) Network Daemon"
    service_names_descr["_scan-target._tcp."] = "Scanner, Printing"
    service_names_descr["_scanner._tcp."] = "Scanners"
    service_names_descr["_servermgr._tcp."] = "Server Admin, Apple"
    service_names_descr["_sftp-ssh._tcp."] = "SFTP File Protocol"
    service_names_descr["_sketchmirror._tcp."] = "Sketch App"
    service_names_descr["_sleep-proxy._udp."] = "Wake-on-Network / Bonjour Sleep Proxy"
    service_names_descr["_smb._tcp."] = "SMB File Protocol"
    service_names_descr["_spotify-connect._tcp."] = "Spotify Connect"
    service_names_descr["_ssh._tcp."] = "SSH"
    service_names_descr["_teamviewer._tcp."] = "TeamViewer"
    service_names_descr["_telnet._tcp."] = "Remote Login (TELNET)"
    service_names_descr["_tftp._tcp."] = "Trivial File Transfer Protocol"
    service_names_descr["_tivo-videos._tcp."] = "Tivo Service Advertising"
    service_names_descr["_touch-able._tcp."] = "Apple TV Remote App (iOS devices)"
    service_names_descr["_tunnel._tcp."] = "Tunnel File Protocol"
    service_names_descr["_udisks-ssh._tcp."] = "Ubuntu / Raspberry Pi Advertisement / disk management tool"
    service_names_descr["_uscan._tcp."] = "HP Printer"
    service_names_descr["_uscans._tcp."] = "HP Printer"
    service_names_descr["_webdav._tcp."] = "WebDAV File System (WEBDAV)"
    service_names_descr["_webdavs._tcp."] = "WebDAV File System (WEBDAV)"
    service_names_descr["_wirecastgodirect._tcp."] = "Wirecast Go Streaming by TeleStream"
    service_names_descr["_withings-aura-bridge._tcp."] = "Sleep tracker Aura Withings"
    service_names_descr["_workstation._tcp."] = "Workgroup Manager"
    service_names_descr["_xserveraid._tcp."] = "Xserve RAID, Apple"
    return service_names_descr
}()

// Default values
struct NetworkDefaults {
    public static let speed_test_chargen_port: UInt16 = 19
    public static let speed_test_discard_port: UInt16 = 9
    public static let speed_test_app_port: UInt16 = 4
    public static let buffer_size = 3000
    public static let local_domain_for_browsing = "local."
    public static let speed_test_chargen_service_type = "_speedtestchargen._tcp."
    public static let speed_test_discard_service_type = "_speedtestdiscard._tcp."
    public static let speed_test_app_service_type = "_speedtestapp._tcp."
    public static let n_icmp_echo_reply = 3
}

enum PopUpMessages: String, CaseIterable {
    case node_info_public_host = "public host"
    case localhost = "local host"
    case scan_TCP_ports = "scan TCP ports"
    case TCP_flood_discard = "TCP flood discard: outgoing throughput"
    case TCP_flood_chargen = "TCP flood chargen: incoming throughput"
    case ICMP_ping = "ICMP (ping)"
    case update_nodes = "update nodes"
    case remove_nodes = "remove nodes"
    case internet_speed = "Internet speed"
    case no_dns = "no public DNS record"
}

public enum COLORS {
    // Utilisé pour retrouver un élément graphique rapidement
    static let test = UIColor.green // vert fluo
    static let test2 = UIColor.systemGreen // vert normal
    static let test3 = UIColor.yellow // jaune normal

    // //////////
    // Thème

    static let standard_background = UIC_RGB(24, 99, 111) // vert foncé
    static let global_background: UIColor = UIC_RGB(208, 186, 69) // jaune
    static let toolbar_background = global_background // jaune
    
    // //////////
    // Couleurs des éléments graphiques

    // Tab bar
    // Titres
    static let tabbar_title = standard_background // UIC_RGB(0, 122, 255)

    // Tab bar background
    static let tabbar_bg = UIColor.lightGray.lighter().lighter() // global_background
    
    static let tabbar_bg5 = Color.red.darker().darker()
    
    // Couleur de fond de la tool bar
    static let toolbar_bg = toolbar_background

    // Sections du left pannel : texte principal
    // Titre
    static let leftpannel_section_title = UIColor(red: 146/255, green: 150/255, blue: 156/255, alpha: 1)
    // Sous-titre
    static let leftpannel_section_subtitle = UIColor(red: 146/255, green: 150/255, blue: 156/255, alpha: 1)
    // Fond
    static let leftpannel_section_bg = UIColor(red: 60/255, green: 57/255, blue: 77/255, alpha: 1)
    
    // Cellules du left pannel quand ce sont les noeuds qui sont affichés
    // Effet 3D entre les cellules
    static let leftpannel_node_rect1_bg = leftpannel_section_bg
    static let leftpannel_node_rect2_bg = UIColor(red: 152/255, green: 171/255, blue: 173/255, alpha: 1)
    // Couleur de fond quand on clique sur éditer pour supprimer une cellule
    static let leftpannel_node_edit_bg = COLORS.standard_background
    // Couleur de fond en cas de sélection d'un node
    static let leftpannel_node_select_bg = COLORS.standard_background

    // Cellules du left pannel quand ce sont les IPs qui sont affichés
    // Couleur du texte
    static let leftpannel_ip_text = UIC_RGB(255, 255, 255) // blanc
    // Couleur du texte quand sélectionné
    static let leftpannel_ip_text_selected = UIC_RGB(82, 83, 239)
    // Opacité du texte
    static let leftpannel_ip_text_opacity : Float = 0.8
    
    // Left pannel
    // Fond de la top bar du left pannel
    static let leftpannel_topbar_bg = global_background
    // Barre du haut du left pannel
    static let leftpannel_topbar_buttons = standard_background
    // Icones de la tool bar
    static let leftpannel_bottombar_buttons = standard_background
    // Fond du left pannel
    static let leftpannel_bg = standard_background

    // Right pannel
    // Fond de la top bar du right pannel
    static let rightpannel_topbar_bg = global_background
    // Chart
    // Fond du chart
    static let chart_bg: UIColor = UIC_RGB(220, 220, 200)
    // Fond du chart avant qu'il ne s'affiche
    static let chart_view_bg = chart_bg
    // Couleur du texte des échelles
    static let chart_scale: UIColor = .systemYellow.darker().darker().darker()
    // Couleur de la valeur du point sélectionné
    static let chart_selected_value = UIC_RGB(0, 0, 0)
    // Couleur de la date du point sélectionné
    static let chart_selected_date = chart_selected_value
    // Couleur des points
    static let chart_point = UIC_RGB(0, 0, 0)
    // Couleur du cercle autour des points
    static let chart_point_circle = UIC_RGB(179, 0, 0)
    // Couleur du triangle du point le plus haut
    static let chart_highest_point_triangle = UIColor.systemYellow.darker().darker().darker()
    // Couleur de la valeur du point le plus haut
    static let chart_highest_point_value = UIColor.systemYellow.darker().darker().darker()
    // Couleur du grid principal
    static let chart_main_grid : UIColor = .systemYellow.darker().darker().darker()
    // Couleur du grid secondaire
    static let chart_sub_grid = chart_main_grid // UIC_RGB(255, 0, 0)
    // Couleur de la courbe
    static let chart_curve = UIC_RGB(0, 0, 0)
    // Flèche
    static let chart_arrow_stroke = UIC_RGB(255, 0, 0)
    static let chart_arrow_fill = UIC_RGB(255, 0, 0)
    // Disque de la position du doigt
    static let chart_finger = UIC_RGB(255, 255, 0)
    // Partie sous le chart
    // Couleur du fond
    static let right_pannel_bg = chart_bg // jaune clair
    static let right_pannel_scroll_bg = chart_bg.lighter()
    
    private static func UIC_RGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UIColor {
        return UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }
}

extension UIColor {
    public func darker() -> UIColor {
        UIColor(Color(cgColor: self.cgColor).darker())
    }
    
    public func lighter() -> UIColor {
        UIColor(Color(cgColor: self.cgColor).lighter())
    }
}

// Code from https://stackoverflow.com/questions/56586055/how-to-get-rgb-components-from-color-in-swiftui
extension Color {
    var components: (hue: Double, saturation: Double, brightness: Double, opacity: Double) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            #fatalError("getHue()")
            return (hue: 1, saturation: 1, brightness: 1, opacity: 1)
        }
        
        return (hue: Double(h), saturation: Double(s), brightness: Double(b), opacity: Double(a))
    }
}

extension Color {
    public func darker() -> Color {
        return Color(hue: components.hue, saturation: components.saturation, brightness: components.brightness * 0.9, opacity: components.opacity)
    }
    
    public func lighter() -> Color {
        return Color(hue: components.hue, saturation: components.saturation, brightness: components.brightness * 1.1, opacity: components.opacity)
    }
}
