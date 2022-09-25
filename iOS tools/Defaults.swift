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

public enum COLORS {
    // Utilisé pour retrouver un élément graphique rapidement
    static let test = UIColor.green // vert fluo
    static let test2 = UIColor.systemGreen // vert normal
    static let test3 = UIColor.yellow // vert normal

    // //////////
    // Thème

    static let standard_background = UIColor(red: 123/255, green: 136/255, blue: 152/255, alpha: 1)

    // //////////
    // Couleurs des éléments graphiques

    // Tab bar
    // Titres
    static let tabbar_title = UIC_RGB(0, 122, 255)

    // Tab bar background
    static let tabbar_bg =
    UIColor(red: 242/255, green: 140/255, blue: 135/255, alpha: 1)
    static let tabbar_bg5 =
    UIColor(red: 242/255, green: 140/255, blue: 135/255, alpha: 1)
    static let tabbar_bg6 =
    UIColor(red: 242/255, green: 140/255, blue: 135/255, alpha: 1)
    static let tabbar_bg7 =
    UIColor(red: 242/255, green: 140/255, blue: 135/255, alpha: 1)

    // Couleur de fond de la tool bar
    static let toolbar_bg = UIColor(red: 242/255, green: 140/255, blue: 135/255, alpha: 1)

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
    static let leftpannel_ip_text = UIC_RGB(0, 0, 0)
    // Couleur du texte quand sélectionné
    static let leftpannel_ip_text_selected = UIC_RGB(82, 83, 239)
    // Opacité du texte
    static let leftpannel_ip_text_opacity : Float = 0.7
    static let leftpannel_ip_bg = UIC_RGB(123, 136, 152)
    
    // Left pannel
    // Fond de la top bar du left pannel
    static let leftpannel_topbar_bg = UIColor(red: 242/255, green: 140/255, blue: 135/255, alpha: 1)
    // Barre du haut du left pannel
    static let leftpannel_topbar_buttons = UIC_RGB(16, 105, 219)
    // Icones de la tool bar
    static let leftpannel_bottombar_buttons = UIC_RGB(16, 105, 219)
    // Fond du left pannel
    static let leftpannel_bg = test2

    // Right pannel
    // font de la top bar du right pannel
    static let rightpannel_topbar_bg = UIColor(red: 242/255, green: 140/255, blue: 135/255, alpha: 1)
    // Chart
    // Fond du chart avant qu'il ne s'affiche
    static let chart_view_bg = test2
    
    private static func UIC_RGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UIColor {
        return UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
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
}
