//
//  Chart.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 11/05/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import SceneKit
import SpriteKit

class ChartNode : SKSpriteNode {
    var zoom: CGFloat = 1
    var grid_size: CGSize

    public init(size: CGSize, grid_size: CGSize) {
        self.grid_size = grid_size

        let path = CGMutablePath()
        var x : CGFloat = 0
        while x <= size.width + grid_size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += grid_size.width
        }
        var y : CGFloat = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width + grid_size.width, y: y))
            y += grid_size.height
        }

        let shape_node = SKShapeNode(path: path)
        shape_node.path = path
        shape_node.strokeColor = UIColor.red
        // pour éviter le flickering, il faut que la ligne soit large, quitte à augmenter la taille de l'image créée et à la réduire à l'écran
        shape_node.lineWidth = 10
        shape_node.zPosition = 0.5

        let oneMoveLeft = SKAction.moveBy(x: -100, y: 0, duration: 1)
        let oneMoveRight = SKAction.moveBy(x: 100, y: 0, duration: 0)
        let oneSequence = SKAction.sequence([oneMoveLeft, oneMoveRight])
        let repeatMove  = SKAction.repeatForever(oneSequence)
        shape_node.run(repeatMove)

        let crop_node = SKCropNode()
        let mask_node = SKSpriteNode(texture: nil, color: UIColor.black, size: CGSize(width: size.width, height: size.height))
        mask_node.anchorPoint = CGPoint(x: 0, y: 0)

//        crop_node.maskNode = mask_node
//        crop_node.addChild(shape_node)
        
        super.init(texture: nil, color: UIColor.black, size: size)

        self.anchorPoint = CGPoint(x: 0, y: 0)

//        self.addChild(crop_node)
        self.addChild(shape_node)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

