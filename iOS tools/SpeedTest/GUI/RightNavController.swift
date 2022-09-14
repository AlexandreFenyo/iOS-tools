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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Manage the navigation bar behaviour
        // pour éviter les problèmes avec iOS15 : https://developer.apple.com/forums/thread/682420
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = COLORS.top_down_background
        navigationBar.standardAppearance = appearance;
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
    }
}
