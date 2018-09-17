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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rv2 = RoundedView2(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        navigationBar.addSubview(rv2)
        
        rv2.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints(
            [
                NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: rv2, attribute: .centerX, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: rv2, attribute: .centerY, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: rv2, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100),
                NSLayoutConstraint(item: rv2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)

            ])

        
        
        //        rightNavController.view.addConstraints([
        //            NSLayoutConstraint(item: rv2, attribute: .centerX, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 64)])
        
        //        rv2.trailingAnchor.constraint(equalTo: rightNavController.view.rightAnchor).isActive = true
        
        //        rv2.translatesAutoresizingMaskIntoConstraints = false
        //        rv2.centerXAnchor.constraint(equalTo: rightNavController.view.centerXAnchor).isActive = true
        //        rv2.rightAnchor.constraint(equalTo: rightNavController.view.rightAnchor, constant: 0).isActive = true
        //rightNavController.view.addConstraints([
        //   NSLayoutConstraint(item: rv2, attribute: .centerX, relatedBy: .equal, toItem: rightNavController.view, attribute: .centerX, multiplier: 1.0, constant: 0)])

    }
}
