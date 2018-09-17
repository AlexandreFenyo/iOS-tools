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
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.setNeedsDisplay()
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        let r : CGFloat = 20
        
        ctx.beginPath()
        ctx.setLineWidth(0)
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.addRect(CGRect(x: 0, y: 0, width: r, height: r))
        ctx.fillPath()
        
        ctx.beginPath()
        ctx.setBlendMode(.clear)
        ctx.move(to: CGPoint(x: r, y: r))
        ctx.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: 1.0 * CGFloat.pi, endAngle: 1.5 * CGFloat.pi, clockwise: false)
        ctx.fillPath()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LeftNavController : UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Left rounded corner
        let rv = RoundedView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        navigationBar.addSubview(rv)
        
        rv.translatesAutoresizingMaskIntoConstraints = false
        
        view.addConstraints(
            [
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: rv, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: rv, attribute: .top, multiplier: 1.0, constant: -20),
                NSLayoutConstraint(item: rv, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40),
                NSLayoutConstraint(item: rv, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40)
            ])
    }
}
