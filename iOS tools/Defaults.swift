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

    static let standard_background = UIC_RGB(24, 99, 111)
    static let global_background: UIColor = UIC_RGB(208, 186, 69)
    static let toolbar_background: UIColor = global_background
    
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
    static let leftpannel_ip_text = UIC_RGB(255, 255, 255)
    // Couleur du texte quand sélectionné
    static let leftpannel_ip_text_selected = UIC_RGB(82, 83, 239)
    // Opacité du texte
    static let leftpannel_ip_text_opacity : Float = 0.8
    
    // Left pannel
    // Fond de la top bar du left pannel
    static let leftpannel_topbar_bg = global_background
    // Barre du haut du left pannel
    static let leftpannel_topbar_buttons = standard_background // UIC_RGB(16, 105, 219)
    // Icones de la tool bar
    static let leftpannel_bottombar_buttons = standard_background // UIC_RGB(16, 105, 219)
    // Fond du left pannel
    static let leftpannel_bg = COLORS.standard_background

    // Right pannel
    // Fond de la top bar du right pannel
    static let rightpannel_topbar_bg = global_background
    // Chart
    // Fond du chart
    static let chart_bg: UIColor = UIC_RGB(220,220,200) // .lightGray.lighter()// standard_background.lighter().lighter() // standard_background
    // Fond du chart avant qu'il ne s'affiche
    static let chart_view_bg = chart_bg
    // Couleur du texte des échelles
    static let chart_scale : UIColor = .systemYellow.darker().darker().darker() // SKColor(red: 0.7, green: 0, blue: 0, alpha: 1)
    // Couleur de la valeur du point sélectionné
    static let chart_selected_value = UIC_RGB(247, 242, 5)
    // Couleur de la date du point sélectionné
    static let chart_selected_date = UIC_RGB(247, 242, 5)
    // Couleur des points
    static let chart_point = UIC_RGB(0, 0, 0)
    // Couleur du cercle autour des points
    static let chart_point_circle = UIC_RGB(179, 0, 0)
    // Couleur du triangle du point le plus haut
    static let chart_highest_point_triangle = UIC_RGB(247, 242, 5)
    // Couleur de la valeur du point le plus haut
    static let chart_highest_point_value = UIC_RGB(247, 242, 5)
    // Couleur du grid principal
    static let chart_main_grid : UIColor = .systemYellow.darker().darker().darker()//.systemYellow // UIC_RGB(255, 0, 0)
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
    static let right_pannel_bg = chart_bg
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
