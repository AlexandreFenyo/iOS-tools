//
//  RightNavController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 17/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

class RightNavController : UINavigationController {
    let r : CGFloat = 20
//    var rv : RoundedCornerView?

    @objc
    func tapScrollView(_ sender: UITapGestureRecognizer) {
        let detail_view_controller = viewControllers[0] as? DetailViewController
        detail_view_controller?.scrollToTop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Scroll to top when touching the top of screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapScrollView(_:)))
        navigationBar.addGestureRecognizer(tapGestureRecognizer)
        
        // Couleur du Edit
        navigationBar.tintColor = COLORS.leftpannel_topbar_buttons

        /* SUPPRIME POUR LE MVP
        rv = RoundedCornerView(radius: r, startAngle: -0.5 * CGFloat.pi, endAngle: 0.0 * CGFloat.pi, arc_center: CGPoint(x: 0, y: r))
        navigationBar.addSubview(rv!)
        
        rv!.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(
            [
                NSLayoutConstraint(item: view!, attribute: .trailing, relatedBy: .equal, toItem: rv, attribute: .trailing, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: navigationBar, attribute: .top, relatedBy: .equal, toItem: rv, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: rv!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: r),
                NSLayoutConstraint(item: rv!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: r)
            ])
         */
        
        // Manage the navigation bar behaviour
        // pour éviter les problèmes avec iOS15 : https://developer.apple.com/forums/thread/682420
        // voir aussi https://developer.apple.com/forums/thread/714278 si warning dans la console avec iOS15
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = COLORS.rightpannel_topbar_bg
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
    }
}
