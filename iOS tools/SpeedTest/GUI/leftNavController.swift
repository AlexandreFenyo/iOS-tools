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
    var rv : RoundedCornerView?

    override func viewDidLoad() {
        super.viewDidLoad()

        rv = RoundedCornerView(radius: r, startAngle: 1.0 * CGFloat.pi, endAngle: 1.5 * CGFloat.pi, arc_center: CGPoint(x: r, y: r))
        navigationBar.addSubview(rv!)

        rv!.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(
            [
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: rv, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: navigationBar, attribute: .top, relatedBy: .equal, toItem: rv, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: rv!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: r),
                NSLayoutConstraint(item: rv!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: r)
            ])
    }
}
