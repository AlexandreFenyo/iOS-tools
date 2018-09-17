//
//  RoundedView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 17/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

class RoundedCornerView : UIView {
    let radius, startAngle, endAngle: CGFloat
    let arc_center: CGPoint

//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        print("XXDID CHANGE")
//        print(traitCollection.horizontalSizeClass.rawValue)
//        if traitCollection.horizontalSizeClass.rawValue == 2 {
//            print("no hidden")
////            self.isHidden = false
//            layer.isHidden = false
//        }
//        else {
//            print("hidden")
// //           self.isHidden = true
//            layer.isHidden = true
//        }
//        layer.setNeedsDisplay()
//        setNeedsDisplay()
//        setNeedsLayout()
//        layer.setNeedsLayout()
//        backgroundColor = .red
//    }

    public init(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, arc_center: CGPoint) {
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.arc_center = arc_center
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
        ctx.move(to: arc_center)
        ctx.addArc(center: arc_center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        ctx.fillPath()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
