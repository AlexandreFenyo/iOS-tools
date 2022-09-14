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

    override func viewDidLoad() {
        super.viewDidLoad()

        ////////////////////////////////////////////////////////////
        // Manage the toolbar background

        let h = toolbar.bounds.height
        let margin : CGFloat = 5
        let d = h - 2 * margin
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: h, height: h))
        let image1 = renderer.image { (context) in
            UIColor.darkGray.setStroke()
//            COLORS.top_down_background.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: margin, y: margin, width: d, height: d))
        }
        let image = image1.resizableImage(withCapInsets: UIEdgeInsets(top: h / 2, left: h / 2, bottom: h / 2, right: h / 2))
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        toolbar.addSubview(imageView)
        toolbar.sendSubviewToBack(imageView)

        // Manage constraints for auto resizing
        imageView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addConstraints(
            [
                NSLayoutConstraint(item: toolbar!, attribute: .leading, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar!, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar!, attribute: .trailing, relatedBy: .equal, toItem: imageView, attribute: .trailing, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar!, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
        
        // Make the toolbar background transparent
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        // Remove the top border of the toolbar
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)

        ////////////////////////////////////////////////////////////
        // Manage the top left rounded corner


        // Manage the navigation bar behaviour
        // pour éviter les problèmes avec iOS15 : https://developer.apple.com/forums/thread/682420
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = COLORS.top_down_background
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
        
        // Manage constraints for auto resizing
    }
}
