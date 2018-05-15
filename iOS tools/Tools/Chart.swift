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

// http://iosfonts.com

class SCNChartNode : SCNNode {
    public init(density: CGFloat, size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, background: SKColor = .clear, font_name: String = "Arial Rounded MT Bold", font_size_ratio: CGFloat = 0.4, font_color: SKColor = SKColor(red: 0.7, green: 0, blue: 0, alpha: 1), debug: Bool = true) {
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
        let chart_node = SKChartNode(size: size, grid_size: grid_size, subgrid_size: subgrid_size, line_width: line_width, left_width: left_width, bottom_height: bottom_height, crop: false, background: background, font_name: font_name, font_size_ratio: font_size_ratio, font_color: font_color, debug: debug)
        chart_node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chart_scene.addChild(chart_node)

        self.scale = SCNVector3(x: 1, y: -1, z: 1)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKChartNode : SKSpriteNode {
    var debug: Bool

    public init(size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, crop: Bool = true, background: SKColor = .clear, font_name: String = "Arial Rounded MT Bold", font_size_ratio: CGFloat = 0.4, font_color: SKColor = SKColor(red: 0.7, green: 0, blue: 0, alpha: 1), debug: Bool = true) {
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
        grid_node.position = CGPoint(x: -size.width / 2 + left_width, y: -size.height / 2 + bottom_height)
        grid_node.path = grid_path
        grid_node.strokeColor = UIColor.red
        grid_node.lineWidth = line_width

        // Create the subgrid
        let subgrid_node: SKShapeNode?
        if (subgrid_size != nil) {
            let subgrid_path = CGMutablePath()
            x = 0
            while x <= size.width + subgrid_size!.width {
                subgrid_path.move(to: CGPoint(x: x, y: 0))
                subgrid_path.addLine(to: CGPoint(x: x, y: size.height))
                x += subgrid_size!.width
            }
            y = 0
            while y <= size.height {
                subgrid_path.move(to: CGPoint(x: 0, y: y))
                subgrid_path.addLine(to: CGPoint(x: size.width + grid_size.width, y: y))
                y += subgrid_size!.height
            }
            subgrid_node = SKShapeNode(path: subgrid_path)
            subgrid_node?.position = CGPoint(x: -size.width / 2 + left_width, y: -size.height / 2 + bottom_height)
            subgrid_node?.path = subgrid_path
            subgrid_node?.strokeColor = UIColor.red
            // In order to avoid flickering on black or dark background, linewidth must be greater than 1
            subgrid_node?.lineWidth = line_width
            subgrid_node?.alpha = 0.3
        } else {
            subgrid_node = nil
        }
        
        // Animate
        let oneMoveLeft = SKAction.moveBy(x: -grid_size.width, y: 0, duration: 1)
        let oneMoveRight = SKAction.moveBy(x: grid_size.width, y: 0, duration: 0)
        let oneSequence = SKAction.sequence([oneMoveLeft, oneMoveRight])
        let repeatMove  = SKAction.repeatForever(oneSequence)
        grid_node.run(repeatMove)
        if subgrid_node != nil { subgrid_node!.run(repeatMove) }

        // Add left mask
        let left_mask_node = SKSpriteNode(color: debug ? .blue : background, size: CGSize(width: left_width, height: size.height))
        if debug { left_mask_node.alpha = 0.5 }
        left_mask_node.position = CGPoint(x: (left_width - size.width) / 2, y: 0)

        // Add a label
        let label_node = SKLabelNode(fontNamed: font_name)
        label_node.text = "You Win!"
        label_node.fontSize = 100
        label_node.fontColor = SKColor.green
        label_node.position = CGPoint(x: 0, y: 0)

        // Instanciate font to get informations about it
        let font = UIFont(name: font_name, size: 100)

        // Create left values
        let left_label_node = SKLabelNode(fontNamed: font_name)
        left_label_node.text = "12345 Mbit/s"
        left_label_node.fontSize = font_size_ratio * grid_size.height / (font?.capHeight)! * 100
        left_label_node.fontColor = font_color
        left_label_node.horizontalAlignmentMode = .right
        left_label_node.position = CGPoint(x: left_width / 2 - left_label_node.fontSize / 2, y: -(font_size_ratio * grid_size.height / 2))
        left_mask_node.addChild(left_label_node)

        // Create self
        super.init(texture: nil, color: debug ? .yellow : background, size: size)

        // Crop the drawing if working in a 2D scene
        let root_node : SKNode
        if crop {
            let crop_node = SKCropNode()
            let mask_node = SKSpriteNode(texture: nil, color:  SKColor.black, size: size)
            if !debug { crop_node.maskNode = mask_node }
            root_node = crop_node
            self.addChild(root_node)
        } else { root_node = self }
        
        root_node.addChild(grid_node)
        if subgrid_node != nil { root_node.addChild(subgrid_node!) }
        root_node.addChild(label_node)
        root_node.addChild(left_mask_node)

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

