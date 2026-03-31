//
//  leftNavController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 17/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// https://medium.com/whoknows-swift/swift-the-hierarchy-of-uinavigationcontroller-programmatically-91631990f495
// https://www.raywenderlich.com/411-core-graphics-tutorial-part-1-getting-started
// https://cocoacasts.com/working-with-auto-layout-in-code

import Foundation
import UIKit

class LeftNavController : UINavigationController {
    let r : CGFloat = 20
//    var rv : RoundedCornerView? // SUPPRIME POUR LE MVP

    @objc
    func tapScrollView(_ sender: UITapGestureRecognizer) {
        let topRow = IndexPath(row: 0, section: 0)
        let masterViewController = topViewController as? MasterViewController
        masterViewController?.tableView.scrollToRow(at: topRow, at: .top, animated: true)
        let masterIPViewController = topViewController as? MasterIPViewController
        masterIPViewController?.tableView.scrollToRow(at: topRow, at: .top, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let h = toolbar.bounds.height
        guard h > 0 else { return }

        // Fond uni de la toolbar (remplace le rendu CALayer de _UIBarBackground qui,
        // en iOS 26, s'affiche en 75 pt alors que le contenu est à 50 pt)
        toolbar.backgroundColor = COLORS.toolbar_bg
        toolbar.layer.cornerRadius = h / 2
        toolbar.clipsToBounds = true

        // Cacher _UIBarBackground : en iOS 26 il utilise un rendu CALayer (glass effect)
        // indépendant de backgroundColor, qui recouvre toolbar.backgroundColor et dont
        // le centre visuel est décalé (75 pt vs 50 pt). iOS peut le recréer après chaque
        // passe de layout, d'où ce masquage systématique ici.
        for sv in toolbar.subviews {
            if NSStringFromClass(type(of: sv)).contains("BarBackground") {
                sv.isHidden = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Scroll to top when touching the top of screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapScrollView(_:)))
        navigationBar.addGestureRecognizer(tapGestureRecognizer)
        
        // Rendre le fond système de la toolbar transparent via UIToolbarAppearance.
        // On ne passe PAS par backgroundImage ici : cette propriété est rendue dans
        // _UIBarBackground dont le frame dépasse de 25pt les bounds de la toolbar en iOS 26
        // (pour couvrir la safe area), ce qui décale le fond par rapport aux icônes.
        // Le fond personnalisé est créé dans viewDidLayoutSubviews avec les bounds réels.
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithTransparentBackground()
        toolbar.standardAppearance = toolbarAppearance
        toolbar.compactAppearance = toolbarAppearance
        toolbar.scrollEdgeAppearance = toolbarAppearance
        toolbar.compactScrollEdgeAppearance = toolbarAppearance
        
        // Manage the navigation bar behaviour
        // pour éviter les problèmes avec iOS15 : https://developer.apple.com/forums/thread/682420
        // En iOS 26 (Liquid Glass), scrollEdgeAppearance doit être un objet distinct avec
        // configureWithOpaqueBackground() pour éviter que le fond soit transparent quand la
        // liste est en position haute (scroll edge).
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = COLORS.leftpannel_topbar_bg
        navigationBar.standardAppearance = appearance

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithOpaqueBackground()
        scrollEdgeAppearance.backgroundColor = COLORS.leftpannel_topbar_bg
        navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationBar.compactScrollEdgeAppearance = scrollEdgeAppearance
    }
}
