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

// Cette liste doit être synchronisée avec les services déclarés dans Info.plist
let service_names = [
    "_adisk._tcp.",
    "_airplay._tcp.",
    "_airport._tcp.",
    "_atc._tcp.",
    "_companion-link._tcp.",
    "_dhnap._tcp.",
    "_ewelink._tcp.",
    "_googlecast._tcp.",
    "_googlezone._tcp.",
    "_hap._tcp.",
    "_homekit._tcp.",
    "_http._tcp.",
    "_hue._tcp.",
    "_ipp._tcp.",
    "_ipps._tcp.",
    "_mediaremotetv._tcp.",
    "_meshcop._udp.",
    "_pdl-datastream._tcp.",
    "_pgpkey-hkp._tcp.",
    "_raop._tcp.",
    "_rdlink._tcp.",
    "_rfb._tcp.",
    "_sane-port._tcp.",
    "_scanner._tcp.",
    "_sengled._udp.",
    "_sftp-ssh._tcp.",
    "_sleep-proxy._udp.",
    "_smb._tcp.",
    "_spotify-connect._tcp.",
    "_ssh._tcp.",
    "_touch-able._tcp.",
    "_viziocast._tcp.",
    "_workstation._tcp.",
    "_adisk._tcp.",
    "_afpovertcp._tcp.",
    "_airdroid._tcp.",
    "_airdrop._tcp.",
    "_airplay._tcp.",
    "_airport._tcp.",
    "_amzn-wplay._tcp.",
    "_apple-mobdev2._tcp.",
    "_apple-sasl._tcp.",
    "_appletv-v2._tcp.",
    "_atc._tcp.",
    "_sketchmirror._tcp.",
    "_bcbonjour._tcp.",
    "_bp2p._tcp.",
    "_companion-link._tcp.",
    "_cloud._tcp.",
    "_daap._tcp.",
    "_device-info._tcp.",
    "_distcc._tcp.",
    "_dpap._tcp.",
    "_eppc._tcp.",
    "_esdevice._tcp.",
    "_esfileshare._tcp.",
    "_ftp._tcp.",
    "_googlecast._tcp.",
    "_googlezone._tcp.",
    "_hap._tcp.",
    "_homekit._tcp.",
    "_home-sharing._tcp.",
    "_http._tcp.",
    "_hudson._tcp.",
    "_ica-networking._tcp.",
    "_ichat._tcp.",
    "_jenkins._tcp.",
    "_KeynoteControl._tcp.",
    "_keynotepair._tcp.",
    "_mediaremotetv._tcp.",
    "_nfs._tcp.",
    "_nvstream._tcp.",
    "_androidtvremote._tcp.",
    "_omnistate._tcp.",
    "_pdl-datastream._tcp.",
    "_photoshopserver._tcp.",
    "_printer._tcp.",
    "_raop._tcp.",
    "_readynas._tcp.",
    "_rfb._tcp.",
    "_physicalweb._tcp.",
    "_riousbprint._tcp.",
    "_rsp._tcp.",
    "_scanner._tcp.",
    "_servermgr._tcp.",
    "_sftp-ssh._tcp.",
    "_sleep-proxy._udp.",
    "_smb._tcp.",
    "_spotify-connect._tcp.",
    "_teamviewer._tcp.",
    "_telnet._tcp.",
    "_touch-able._tcp.",
    "_tunnel._tcp.",
    "_udisks-ssh._tcp.",
    "_webdav._tcp.",
    "_workstation._tcp.",
    "_xserveraid._tcp."
]

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
    case TCP_flood_discard = "TCP flood discard: outgoing throuhgput"
    case TCP_flood_chargen = "TCP flood chargen: incoming throuhgput"
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
    static let test3 = UIColor.yellow // vert normal

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
    static let tabbar_bg = global_background
    
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
    static let chart_scale : UIColor = .systemYellow.darker().darker().darker()
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
            fatalError("getHue()")
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
