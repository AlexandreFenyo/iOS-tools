//
//  leftNavController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 17/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

class LeftNavController : UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Left rounded corner
        let rv = RoundedView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        navigationBar.addSubview(rv)
    }
}
