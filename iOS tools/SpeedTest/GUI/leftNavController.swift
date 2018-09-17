//
//  leftNavController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 17/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

class RoundedView : UIView {
    let radius : CGFloat

    public init(radius: CGFloat) {
        self.radius = radius
        super.init(frame: .zero)
        backgroundColor = .clear
        layer.setNeedsDisplay()
    }

    override func draw(_ layer: CALayer, in ctx: CGContext) {
        ctx.beginPath()
        ctx.setLineWidth(0)
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.addRect(CGRect(x: 0, y: 0, width: radius, height: radius))
        ctx.fillPath()
        
        ctx.beginPath()
        ctx.setBlendMode(.clear)
        ctx.move(to: CGPoint(x: radius, y: radius))
        ctx.addArc(center: CGPoint(x: radius, y: radius), radius: radius, startAngle: 1.0 * CGFloat.pi, endAngle: 1.5 * CGFloat.pi, clockwise: false)
        ctx.fillPath()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LeftNavController : UINavigationController {
    let r : CGFloat = 20

    override func viewDidLoad() {
        super.viewDidLoad()

        let rv = RoundedView(radius: r)
        navigationBar.addSubview(rv)
        
        rv.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(
            [
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: rv, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: navigationBar, attribute: .top, relatedBy: .equal, toItem: rv, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: rv, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: r),
                NSLayoutConstraint(item: rv, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: r)
            ])
    }
}
