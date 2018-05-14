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

class SCNChartNode : SCNNode {
    public init(density: CGFloat, size: CGSize, grid_size: CGSize, line_width: CGFloat, background: SKColor = .clear, debug: Bool = true) {
        super.init()

        // Create a 2D scene
        let chart_scene = SKScene(size: size)
        chart_scene.backgroundColor = SKColor.white

        // Create a 3D plan containing the 2D scene
        self.geometry = SCNPlane(width: size.width / density, height: size.height / density)
        self.geometry?.firstMaterial?.isDoubleSided = true
        self.geometry?.firstMaterial?.diffuse.contents = chart_scene

        // Create a 2D chart and add it to the scene
        // Note: cropping this way does not seem to work in a 3D env with GL instead of Metal
        // tester avec crop: true
        let chart_node = SKChartNode(size: size, grid_size: grid_size, line_width: line_width, crop: false, background: background, debug: debug)
        chart_node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chart_scene.addChild(chart_node)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKChartNode : SKSpriteNode {
    var debug: Bool

    public init(size: CGSize, grid_size: CGSize, line_width: CGFloat, crop: Bool = true, background: SKColor = .clear, debug: Bool = true) {
        self.debug = debug

        // Create the main grid
        let grid_path = CGMutablePath()
        var x : CGFloat = 0
        while x <= size.width + grid_size.width {
            grid_path.move(to: CGPoint(x: x, y: 0))
            grid_path.addLine(to: CGPoint(x: x, y: size.height))
            x += grid_size.width
        }
        var y : CGFloat = 0
        while y <= size.height {
            grid_path.move(to: CGPoint(x: 0, y: y))
            grid_path.addLine(to: CGPoint(x: size.width + grid_size.width, y: y))
            y += grid_size.height
        }
        let grid_node = SKShapeNode(path: grid_path)
        grid_node.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        grid_node.path = grid_path
        grid_node.strokeColor = UIColor.red

        // In order to avoid flickering on black or dark background, linewidth must be greater than 1
        grid_node.lineWidth = line_width

        // Animate
        let oneMoveLeft = SKAction.moveBy(x: -grid_size.width, y: 0, duration: 1)
        let oneMoveRight = SKAction.moveBy(x: grid_size.width, y: 0, duration: 0)
        let oneSequence = SKAction.sequence([oneMoveLeft, oneMoveRight])
        let repeatMove  = SKAction.repeatForever(oneSequence)
        grid_node.run(repeatMove)

        // Crop the drawing if working in a 3D scene
        let crop_node: SKCropNode?
        if crop {
            crop_node = SKCropNode()
            let mask_node = SKSpriteNode(texture: nil, color: SKColor.black, size: size)
            crop_node!.maskNode = mask_node
            crop_node!.addChild(grid_node)
        } else { crop_node = nil }
        
        super.init(texture: nil, color: debug ? .yellow : background, size: size)

        self.addChild(crop_node ?? grid_node)

        if debug {
            // Add a black square at the center of the chart
            let square_node = SKSpriteNode(color: UIColor.black, size: CGSize(width: self.size.width / 10, height: self.size.height / 10))
            square_node.alpha = 0.5
            self.addChild(square_node)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

