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

// Default values
struct ChartDefaults {
    // See http://iosfonts.com
    static let font_name = "Arial Rounded MT Bold"

    static let font_size_ratio : CGFloat = 0.4
    static let font_color = SKColor(red: 0.7, green: 0, blue: 0, alpha: 1)
}

// A Label Node with additional atributes
class SKExtLabelNode : SKLabelNode {
    // Date displayed by the label
    private var _date : Date?
    public var date : Date? {
        get { return _date }
        set {
            _date = newValue
            self.text = SKExtLabelNode.formatter.string(from: newValue!)
        }
    }

    // Static date formatter shared by every instances
    static private let formatter : DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    public override init() {
        super.init()
    }
    
    public init(fontNamed fontName: String?, date: Date) {
        super.init(fontNamed: fontName)
        self.date = date
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SCNChartNode : SCNNode {
    public init(density: CGFloat, size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, vertical_unit: String, vertical_cost: CGFloat, date: Date, grid_time_interval: TimeInterval, background: SKColor = .clear, font_name: String = ChartDefaults.font_name, font_size_ratio: CGFloat = ChartDefaults.font_size_ratio, font_color: SKColor = ChartDefaults.font_color, debug: Bool = true) {
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
        let chart_node = SKChartNode(size: size, grid_size: grid_size, subgrid_size: subgrid_size, line_width: line_width, left_width: left_width, bottom_height: bottom_height, vertical_unit: vertical_unit, vertical_cost: vertical_cost, date: date, grid_time_interval: grid_time_interval, crop: false, background: background, font_name: font_name, font_size_ratio: font_size_ratio, font_color: font_color, debug: debug)
        chart_node.anchorPoint = CGPoint(x: 0, y: 0)
        chart_scene.addChild(chart_node)

        self.scale = SCNVector3(x: 1, y: -1, z: 1)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKChartNode : SKSpriteNode {
    private var debug: Bool
    private var right_display_date: Date

    public init(size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, vertical_unit: String, vertical_cost: CGFloat, date: Date, grid_time_interval: TimeInterval, crop: Bool = true, background: SKColor = .clear, font_name: String = ChartDefaults.font_name, font_size_ratio: CGFloat = ChartDefaults.font_size_ratio, font_color: SKColor = ChartDefaults.font_color, debug: Bool = true) {
        self.debug = debug
        
        // Create the main grid
        let grid_path = CGMutablePath()
        var x : CGFloat = 0
        while x <= size.width - left_width + 2 * grid_size.width {
            grid_path.move(to: CGPoint(x: x, y: 0))
            grid_path.addLine(to: CGPoint(x: x, y: size.height - bottom_height))
            x += grid_size.width
        }
        var y : CGFloat = 0
        while y <= size.height - bottom_height {
            grid_path.move(to: CGPoint(x: 0, y: y))
            grid_path.addLine(to: CGPoint(x: size.width - left_width + 2 * grid_size.width, y: y))
            y += grid_size.height
        }
        let grid_node = SKShapeNode(path: grid_path)
        grid_node.path = grid_path
        grid_node.strokeColor = UIColor.red
        grid_node.lineWidth = line_width

        // Create the subgrid
        let subgrid_node: SKShapeNode?
        if (subgrid_size != nil) {
            let subgrid_path = CGMutablePath()
            x = 0
            while x <= size.width - left_width + 2 * grid_size.width {
                subgrid_path.move(to: CGPoint(x: x, y: 0))
                subgrid_path.addLine(to: CGPoint(x: x, y: size.height - bottom_height))
                x += subgrid_size!.width
            }
            y = 0
            while y <= size.height - bottom_height {
                subgrid_path.move(to: CGPoint(x: 0, y: y))
                subgrid_path.addLine(to: CGPoint(x: size.width - left_width + 2 * grid_size.width, y: y))
                y += subgrid_size!.height
            }
            subgrid_node = SKShapeNode(path: subgrid_path)
            subgrid_node?.path = subgrid_path
            subgrid_node?.strokeColor = UIColor.red
            // In order to avoid flickering on black or dark background, linewidth must be greater than 1
            subgrid_node?.lineWidth = line_width
            subgrid_node?.alpha = 0.3
        } else {
            subgrid_node = nil
        }
        
        // Add left mask
        let left_mask_node = SKSpriteNode(color: debug ? .blue : background, size: CGSize(width: left_width, height: size.height))
        left_mask_node.anchorPoint = CGPoint(x: 0, y: 0)
        if debug { left_mask_node.alpha = 0.5 }

        // Instanciate font to get informations about it
        let font = UIFont(name: font_name, size: 1) ?? UIFont.preferredFont(forTextStyle: .body)

        // Create y-axis values
        y = 0
        while y <= size.height - bottom_height {
            // Add quantity
            let left_label_node = SKLabelNode(fontNamed: font_name)
            left_label_node.text = String(Int(vertical_cost * y)) + " " + vertical_unit
            left_label_node.fontSize = font_size_ratio * grid_size.height / font.capHeight * font.pointSize
            left_label_node.fontColor = font_color
            left_label_node.horizontalAlignmentMode = .right
            left_mask_node.addChild(left_label_node)
            left_label_node.position = CGPoint(x: left_width - left_label_node.fontSize / 2, y: y + bottom_height - font_size_ratio * grid_size.height / 2)
            
            // Add hyphen
            let hyphen_node = SKSpriteNode(color: grid_node.strokeColor, size: CGSize(width: left_label_node.fontSize / 4, height: grid_node.lineWidth))
            hyphen_node.anchorPoint = CGPoint(x: 1, y: 0.5)
            left_mask_node.addChild(hyphen_node)
            hyphen_node.position = CGPoint(x: left_width, y: y + bottom_height)

            y += grid_size.height
        }

        // Add bottom mask
        let bottom_mask_node = SKSpriteNode(color: debug ? .blue : .clear, size: CGSize(width: size.width - left_width + 2 * grid_size.width, height: bottom_height))
        bottom_mask_node.anchorPoint = CGPoint(x: 0, y: 1)
        if debug { bottom_mask_node.alpha = 1 }

        // Create x-axis values
        right_display_date = date

        let _formatter = DateFormatter()
        _formatter.dateFormat = "HHmmss"
        _formatter.locale = Locale(identifier: "en_US")
        let _s = _formatter.string(from: date)
        let hours_today = Double(_s.sub(0, 2))!
        let minutes_today = Double(_s.sub(2, 2))!
        let seconds_today = Double(_s.sub(4))!

        print("start date:", date)
        
        // time_offset: time interval between the current date and the nearest date in the past that is aligned with grid_time_interval, so that it can be written simply
        // grid_time_interval:
        //   - if < 60: must divide 60
        //   - if >= 60 and < 3600: must divide 3600
        var time_offset = date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1) + seconds_today.truncatingRemainder(dividingBy: grid_time_interval)
        if grid_time_interval >= 60 { time_offset += 60 * minutes_today.truncatingRemainder(dividingBy: grid_time_interval / 60) }
        if grid_time_interval >= 3600 { time_offset += 3600 * hours_today.truncatingRemainder(dividingBy: grid_time_interval / 3600) }
        // date_rounded: date corresponding the the last grid line displayed
        let date_rounded = date.addingTimeInterval(-time_offset)
        let horizontal_offset = grid_size.width * CGFloat(time_offset / grid_time_interval)

        var current_date = date_rounded
        x = size.width - left_width - (size.width - left_width).remainder(dividingBy: grid_size.width)
        
        while x >= 0 {
            // Add date
            let bottom_label_node = SKExtLabelNode(fontNamed: font_name, date: current_date)
            bottom_label_node.verticalAlignmentMode = .top
            bottom_label_node.horizontalAlignmentMode = .left
            
            bottom_label_node.zRotation = -CGFloat.pi / 4
            bottom_label_node.fontSize = font_size_ratio * grid_size.height / font.capHeight * font.pointSize
            bottom_label_node.fontColor = font_color
            bottom_mask_node.addChild(bottom_label_node)
            bottom_label_node.position = CGPoint(x: x, y: -bottom_label_node.fontSize / 2)
            bottom_label_node.name = "date-" + String(date_rounded.timeIntervalSince1970)

            // Add hyphen
            let hyphen_node = SKSpriteNode(color: grid_node.strokeColor, size: CGSize(width: grid_node.lineWidth, height: bottom_label_node.fontSize / 4))
            hyphen_node.anchorPoint = CGPoint(x: 0.5, y: 1)
            bottom_mask_node.addChild(hyphen_node)
            hyphen_node.position = CGPoint(x: x, y: 0)

            x -= grid_size.width
            current_date.addTimeInterval(-grid_time_interval)
        }

        // Create self
        super.init(texture: nil, color: debug ? .yellow : background, size: size)
        self.anchorPoint = CGPoint(x: 0, y: 0)

        // Animate
        let first_move_left_action = SKAction.moveBy(x: horizontal_offset - grid_size.width, y: 0, duration: grid_time_interval - time_offset)
        let first_move_right_action = SKAction.moveBy(x: grid_size.width, y: 0, duration: 0)
        let first_move_start_loop_action = SKAction.customAction(withDuration: 0, actionBlock: {
            _, _ in
            self.update_xaxis(bottom_mask_node: bottom_mask_node, size: size, left_width: left_width, grid_size: grid_size, grid_time_interval: grid_time_interval)
            let move_left_action = SKAction.moveBy(x: -grid_size.width, y: 0, duration: grid_time_interval)
            let move_right_action = SKAction.moveBy(x: grid_size.width, y: 0, duration: 0)
            let handle_loop_action = SKAction.customAction(withDuration: 0, actionBlock: {
                _, _ in self.update_xaxis(bottom_mask_node: bottom_mask_node, size: size, left_width: left_width, grid_size: grid_size, grid_time_interval: grid_time_interval)
            })
            let sequence_action = SKAction.sequence([move_left_action, move_right_action, handle_loop_action])
            let repeat_action = SKAction.repeatForever(sequence_action)
            grid_node.run(repeat_action)

        })
        let sequence_action = SKAction.sequence([first_move_left_action, first_move_right_action, first_move_start_loop_action])
        grid_node.run(sequence_action)

        // Crop the drawing if working in a 2D scene
        let root_node : SKNode
        if crop {
            let crop_node = SKCropNode()
            let mask_node = SKSpriteNode(texture: nil, color:  SKColor.black, size: size)
            mask_node.anchorPoint = CGPoint(x: 0, y: 0)

            if !debug { crop_node.maskNode = mask_node }
            root_node = crop_node
            self.addChild(root_node)
        } else { root_node = self }

        root_node.addChild(grid_node)

        grid_node.position = CGPoint(x: left_width - horizontal_offset, y: bottom_height)
        
        if subgrid_node != nil { grid_node.addChild(subgrid_node!) }
        grid_node.addChild(bottom_mask_node)
        root_node.addChild(left_mask_node)

        if debug {
            // Add a black square at the center of the chart
            let square_node = SKSpriteNode(color: UIColor.black, size: CGSize(width: self.size.width / 10, height: self.size.height / 10))
            square_node.alpha = 0.5
            self.addChild(square_node)
            square_node.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        }
    }
    
    private func update_xaxis(bottom_mask_node: SKSpriteNode, size: CGSize, left_width: CGFloat, grid_size: CGSize, grid_time_interval: TimeInterval) {
        right_display_date.addTimeInterval(grid_time_interval)
        bottom_mask_node.enumerateChildNodes(withName: "//date-*", using: {
            node, _ in node.position.x -= grid_size.width
        })

        // Find both extreme date nodes
        var leftmost_node : SKNode?
        var rightmost_node : SKNode?
        bottom_mask_node.enumerateChildNodes(withName: "//date-*", using: {
            node, _ in

            if let posx = leftmost_node?.position.x {
                if node.position.x < posx { leftmost_node = node }
            } else { leftmost_node = node }

            if let posx = rightmost_node?.position.x {
                if node.position.x > posx { rightmost_node = node }
            } else { rightmost_node = node }
        })

        // set the left-most node to the right of the right-most node
        if leftmost_node != nil && rightmost_node != nil {
            let node = leftmost_node! as! SKExtLabelNode
            node.date!.addTimeInterval(TimeInterval(Double(1 + ((rightmost_node!.position.x - leftmost_node!.position.x) / grid_size.width)) * grid_time_interval))
            node.position.x = rightmost_node!.position.x + grid_size.width
        }
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

