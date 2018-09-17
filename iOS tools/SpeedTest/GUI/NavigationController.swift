//
//  NavigationBar.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// https://medium.com/whoknows-swift/swift-the-hierarchy-of-uinavigationcontroller-programmatically-91631990f495
// https://www.raywenderlich.com/411-core-graphics-tutorial-part-1-getting-started
// https://cocoacasts.com/working-with-auto-layout-in-code
import Foundation
import UIKit
import CoreGraphics

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

class RoundedView2 : UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
//        backgroundColor = .clear
//        backgroundColor =

backgroundColor = .red


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
