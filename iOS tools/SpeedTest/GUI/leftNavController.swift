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

//    override func viewDidAppear(_ animated: Bool) {
//        let renderer = UIGraphicsImageRenderer(size: toolbar.bounds.size)
//        let image = renderer.image { (context) in
//            UIColor.darkGray.setStroke()
//            context.stroke(renderer.format.bounds)
//            UIColor(red: 158/255, green: 215/255, blue: 245/255, alpha: 1).setFill()
//            context.fill(CGRect(x: 10, y: 10, width: toolbar.bounds.size.width - 80, height: toolbar.bounds.size.height - 20))
//        }
//        toolbar.setBackgroundImage(image, forToolbarPosition: .bottom, barMetrics: .default)
//        toolbar.contentMode = .scaleToFill
//        toolbar.subviews.first?.contentMode = .scaleToFill
//        for i in toolbar.subviews {
//            i.contentMode = .scaleToFill
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()



        // stretch : https://developer.apple.com/documentation/uikit/uiimage
        // https://stackoverflow.com/questions/27153181/how-do-you-make-a-background-image-scale-to-screen-size-in-swift
        // Set the toolbar background
        // toolbar.tintColor = .red
//	        toolbar.back
        //        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 40))
        let renderer = UIGraphicsImageRenderer(size: toolbar.bounds.size)
        let image1 = renderer.image { (context) in
            UIColor.darkGray.setStroke()
            context.stroke(renderer.format.bounds)
            UIColor(red: 158/255, green: 215/255, blue: 245/255, alpha: 1).setFill()
//            context.fill(CGRect(x: 10, y: 10, width: toolbar.bounds.size.width - 20, height: toolbar.bounds.size.height - 20))
//            context.cgContext.addEllipse(in: CGRect(x: 1, y: 1, width: 20, height: 20))
//            context.cgContext.drawPath(using: .fillStroke)
            context.cgContext.fillEllipse(in: CGRect(x: 5, y: 5, width: toolbar.bounds.size.height - 10, height: toolbar.bounds.size.height - 10))
            context.cgContext.fillEllipse(in: CGRect(x: toolbar.bounds.size.width - 5 - (toolbar.bounds.size.height - 10), y: 5, width: toolbar.bounds.size.height - 10, height: toolbar.bounds.size.height - 10))

        }
        let image2 = UIImage(named: "netmon7")
        if image2 == nil { exit(1) }
        let image = image1.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 10, bottom: toolbar.bounds.size.width - 20, right: toolbar.bounds.size.height - 20))
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        toolbar.addSubview(imageView)
        toolbar.sendSubview(toBack: imageView)
        // regarder les contraintes en trop
        imageView.translatesAutoresizingMaskIntoConstraints = false
//        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addConstraints(
            [
                NSLayoutConstraint(item: toolbar, attribute: .leading, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar, attribute: .trailing, relatedBy: .equal, toItem: imageView, attribute: .trailing, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
        
        // Make the toolbar background transparent
        toolbar.setBackgroundImage(UIGraphicsImageRenderer(bounds: CGRect(x: 0, y: 0, width: 1, height: 1)).image(actions: { _ in }), forToolbarPosition: .bottom, barMetrics: .default)
        
        
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
