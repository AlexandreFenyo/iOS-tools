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
    var rv : RoundedCornerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }
}
