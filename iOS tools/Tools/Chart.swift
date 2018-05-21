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

struct TimeSeriesElement {
    public let date : Date
    public let value : Float
}

protocol TimeSeriesReceiver {
    func newData(manager: TimeSeries, value: TimeSeriesElement)
}

class TimeSeries {
    private var receivers: [TimeSeriesReceiver] = []
    private var data: [Date: TimeSeriesElement] = [:]
    // Ordered data keys (dates)
    private var keys: [Date] = []

    public init() { }
    
    public func register(_ receiver: TimeSeriesReceiver) {
        receivers.append(receiver)
    }

    public func add(_ elt: TimeSeriesElement) {
        // Update backing store
        if data[elt.date] != nil { return }
        data[elt.date] = elt
        let next_date = keys.first(where: { (date) in date > elt.date })
        let idx = next_date != nil ? keys.index(of: next_date!)! : 0
        keys.insert(elt.date, at: idx)

        // Signal about new value
        for receiver in receivers { receiver.newData(manager: self, value: elt) }
    }

    // Ordered array of every elements
    public func getElements() -> [TimeSeriesElement] {
        var elts : [TimeSeriesElement] = []
        for key in keys { elts.append(data[key]!) }
        return elts
    }
}

// A Label Node with additional atributes
class SKExtLabelNode : SKLabelNode {
    // Date displayed by the label
    public var date : Date? {
        willSet { self.text = SKExtLabelNode.formatter.string(from: newValue!) }
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
        defer { self.date = date }
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SCNChartNode : SCNNode {
    public init(ts: TimeSeries, density: CGFloat, full_size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, vertical_unit: String, grid_vertical_cost: CGFloat, date: Date, grid_time_interval: TimeInterval, background: SKColor = .clear, font_name: String = ChartDefaults.font_name, font_size_ratio: CGFloat = ChartDefaults.font_size_ratio, font_color: SKColor = ChartDefaults.font_color, debug: Bool = true) {
        super.init()

        // Create a 2D scene
        let chart_scene = SKScene(size: full_size)
        chart_scene.backgroundColor = SKColor.white

        // Create a 3D plan containing the 2D scene
        self.geometry = SCNPlane(width: full_size.width / density, height: full_size.height / density)
        self.geometry?.firstMaterial?.isDoubleSided = true
        self.geometry?.firstMaterial?.diffuse.contents = chart_scene

        // Create a 2D chart and add it to the scene
        // Note: cropping this way does not seem to work in a 3D env with GL instead of Metal (ex.: Hackintosh running on esx-i)
        let chart_node = SKChartNode(ts: ts, full_size: full_size, grid_size: grid_size, subgrid_size: subgrid_size, line_width: line_width, left_width: left_width, bottom_height: bottom_height, vertical_unit: vertical_unit, grid_vertical_cost: grid_vertical_cost, date: date, grid_time_interval: grid_time_interval, crop: false, background: background, font_name: font_name, font_size_ratio: font_size_ratio, font_color: font_color, debug: debug)
        chart_node.anchorPoint = CGPoint(x: 0, y: 0)
        chart_scene.addChild(chart_node)

        self.scale = SCNVector3(x: 1, y: -1, z: 1)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKChartNode : SKSpriteNode, TimeSeriesReceiver {
    private var debug: Bool

    // State variables
    private var full_size: CGSize
    private var grid_size: CGSize
    private var left_width: CGFloat
    private var bottom_height: CGFloat
    private var grid_time_interval: TimeInterval

    // Properties derivating from state variables
    private var graph_width : CGFloat?
    private var graph_height : CGFloat?
    private var grid_full_width: CGFloat?
    private var grid_full_height: CGFloat?
    // Right-most displayed grid column width
    private var horizontal_remainder: CGFloat?
    private var grid_vertical_cost: CGFloat?

    // Date corresponding to the graph_width position relative to the grid origin
    private var right_display_date: Date

    private func updateStateVariables() {
        // Graph displayed size
        graph_width = full_size.width - left_width
        graph_height = full_size.height - bottom_height
        // Graph real size
        grid_full_width = graph_width!.truncatingRemainder(dividingBy: grid_size.width) == 0 ? graph_width! + grid_size.width : grid_size.width * (2 + graph_width! / grid_size.width).rounded(.down)
        grid_full_height = graph_height!.truncatingRemainder(dividingBy: grid_size.height) == 0 ? graph_height! : grid_size.height * (graph_height! / grid_size.height).rounded(.up)
        // Right-most displayed grid column width
        horizontal_remainder = graph_width!.truncatingRemainder(dividingBy: grid_size.width)
    }

    // convert a TimeSeriesElement to a point relative to the grid origin
    private func toPoint(tse: TimeSeriesElement) -> CGPoint {
        return CGPoint(x: graph_width! + CGFloat((tse.date.timeIntervalSince(right_display_date) / grid_time_interval)) * grid_size.width, y: CGFloat(tse.value) / grid_vertical_cost! * grid_size.height)
    }

    // Rules:
    // - grid_size.width <= size.width - left_width
    // - grid_size.height <= size.height - bottom_height
    // - subgrid_size.width must divide grid_size.width
    // - subgrid_size.height must divide grid_size.height
    // - grid_time_interval:
    //   - if < 60: must divide 60
    //   - if >= 60 and < 3600: must be a multiple of 60 and divide 3600
    //   - if >= 3600: must be a multiple of 3600
    public init(ts: TimeSeries, full_size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, vertical_unit: String, grid_vertical_cost: CGFloat, date: Date, grid_time_interval: TimeInterval, crop: Bool = true, background: SKColor = .clear, font_name: String = ChartDefaults.font_name, font_size_ratio: CGFloat = ChartDefaults.font_size_ratio, font_color: SKColor = ChartDefaults.font_color, debug: Bool = true) {
        self.debug = debug

        // Save state
        self.full_size = full_size
        self.grid_size = grid_size
        self.left_width = left_width
        self.bottom_height = bottom_height
        self.grid_time_interval = grid_time_interval
        self.grid_vertical_cost = grid_vertical_cost
        right_display_date = date

        // Create self
        super.init(texture: nil, color: debug ? .cyan : background, size: full_size)
        updateStateVariables()
        self.anchorPoint = CGPoint(x: 0, y: 0)
        ts.register(self)

        assert(grid_size.width <= full_size.width - left_width)
        assert(grid_size.height <= full_size.height - bottom_height)
        assert(subgrid_size != nil ? grid_size.width.truncatingRemainder(dividingBy: subgrid_size!.width) == 0 : true)
        assert(subgrid_size != nil ? grid_size.height.truncatingRemainder(dividingBy: subgrid_size!.height) == 0 : true)
        assert(grid_time_interval >= 60 || 60.0.truncatingRemainder(dividingBy: grid_time_interval) == 0)
        assert((grid_time_interval < 60 || grid_time_interval > 3600) || (grid_time_interval.truncatingRemainder(dividingBy: 60) == 0 && 3600.0.truncatingRemainder(dividingBy: grid_time_interval) == 0))
        assert(grid_time_interval < 3600 || grid_time_interval.truncatingRemainder(dividingBy: 3600) == 0)

        // Create the main grid
        // Since vertical grid lines have a thickness, we need to include one more right-most grid line (horizontal lines up to this right-most position are not sufficient)
        // Idem for horizontal grid lines: include one more top-most grid line
        let grid_path = CGMutablePath()
        var x : CGFloat = 0
        // There is at least two vertical grid lines
        while x <= grid_full_width! {
            grid_path.move(to: CGPoint(x: x, y: 0))
            grid_path.addLine(to: CGPoint(x: x, y: grid_full_height!))
            x += grid_size.width
        }
        var y : CGFloat = 0
        // There is at least two horizontal grid lines
        while y <= grid_full_height! {
            grid_path.move(to: CGPoint(x: 0, y: y))
            grid_path.addLine(to: CGPoint(x: grid_full_width!, y: y))
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
            while (x <= grid_full_width!) {
                if x.truncatingRemainder(dividingBy: grid_size.width) != 0 {
                    subgrid_path.move(to: CGPoint(x: x, y: 0))
                    subgrid_path.addLine(to: CGPoint(x: x, y: grid_full_height!))
                }
                x += subgrid_size!.width
            }
            y = 0
            while y <= grid_full_height! {
                if y.truncatingRemainder(dividingBy: grid_size.height) != 0 {
                    subgrid_path.move(to: CGPoint(x: 0, y: y))
                    subgrid_path.addLine(to: CGPoint(x: grid_full_width!, y: y))
                }
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
        let left_mask_node = SKSpriteNode(color: debug ? .blue : background, size: CGSize(width: left_width, height: full_size.height))
        left_mask_node.anchorPoint = CGPoint(x: 0, y: 0)
        if debug { left_mask_node.alpha = 0.5 }

        // Instanciate font to get informations about it
        let font = UIFont(name: font_name, size: 1) ?? UIFont.preferredFont(forTextStyle: .body)

        // Create y-axis values
        y = 0
        while y <= graph_height! {
            // Add quantity
            let left_label_node = SKLabelNode(fontNamed: font_name)
            left_label_node.text = String(Int(grid_vertical_cost * y)) + " " + vertical_unit
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
        let bottom_mask_node = SKSpriteNode(color: debug ? .blue : .clear, size: CGSize(width: grid_full_width!, height: bottom_height))
        bottom_mask_node.anchorPoint = CGPoint(x: 0, y: 1)
        if debug { bottom_mask_node.alpha = 1 }
        
        // Create x-axis date values
        let _formatter = DateFormatter()
        _formatter.dateFormat = "HHmmss"
        _formatter.locale = Locale(identifier: "en_US")
        let _s = _formatter.string(from: date)
        let hours_today = TimeInterval(_s.sub(0, 2))!
        let minutes_today = TimeInterval(_s.sub(2, 2))!
        let seconds_today = TimeInterval(_s.sub(4))!

        // time_offset: time interval between the current date and the nearest date in the past that is aligned with grid_time_interval, so that it can be written simply
        // time_offset < grid_time_interval
        var time_offset = date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1) + seconds_today.truncatingRemainder(dividingBy: grid_time_interval)
        if grid_time_interval >= 60 { time_offset += 60 * minutes_today.truncatingRemainder(dividingBy: grid_time_interval / 60) }
        if grid_time_interval >= 3600 { time_offset += 3600 * hours_today.truncatingRemainder(dividingBy: grid_time_interval / 3600) }
        // date_rounded: date printed behind the last grid line displayed
        let date_rounded = date.addingTimeInterval(-time_offset)
        // horizontal length corresponding to time_offset
        let horizontal_time_offset = grid_size.width * CGFloat(time_offset / grid_time_interval)

        var current_date = date_rounded
        x = grid_full_width!
        if horizontal_time_offset >= horizontal_remainder! {
            grid_node.position = CGPoint(x: left_width - (horizontal_time_offset - horizontal_remainder!), y: bottom_height)
            current_date = date_rounded.addingTimeInterval(grid_time_interval * 2)
        } else {
            grid_node.position = CGPoint(x: left_width + (horizontal_remainder! - horizontal_time_offset) - grid_size.width, y: bottom_height)
            current_date = date_rounded.addingTimeInterval(grid_time_interval)
        }
        
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






        // Add curve
        let curve_path = UIBezierPath()

        let elts = ts.getElements()
        print("COUNT: ", elts.count)
        let truc = ts.getElements()
        print("COUNT truc: ", truc.count)
        if elts.count > 0 {
            if elts.count > 1 {
                print("move to:", toPoint(tse: elts[0]).x, toPoint(tse: elts[0]).y)
                curve_path.move(to: toPoint(tse: elts[0]))
                for p in elts.suffix(from: 1) {
                    print("add line to:", toPoint(tse: p).x, toPoint(tse: p).y)
                    curve_path.addLine(to: toPoint(tse: p))
                }
            } else {
                print("should not be here")
            }
        }

        curve_path.move(to: CGPoint(x: 180, y: 80))
        curve_path.addLine(to: CGPoint(x: 200, y: 100))
        curve_path.addLine(to: CGPoint(x: 250, y: 100))
//        curve_path.close()

        // génère warnings
//        curve_path.fill()
//        curve_path.stroke()

        let curve_node = SKShapeNode(path: curve_path.cgPath)
        curve_node.lineWidth = line_width
        curve_node.strokeColor = UIColor.white








        // Animate
        let first_move_left_action = SKAction.moveBy(x: -(grid_size.width - (left_width - grid_node.position.x)), y: 0, duration: grid_time_interval * TimeInterval(((grid_size.width - (left_width - grid_node.position.x)) / grid_size.width)))
        let first_move_right_action = SKAction.moveBy(x: grid_size.width, y: 0, duration: 0)
        let first_move_start_loop_action = SKAction.customAction(withDuration: 0, actionBlock: {
            _, _ in
            self.update_xaxis(bottom_mask_node: bottom_mask_node, curve_node: curve_node)
            let move_left_action = SKAction.moveBy(x: -grid_size.width, y: 0, duration: grid_time_interval)
            let move_right_action = SKAction.moveBy(x: grid_size.width, y: 0, duration: 0)
            let handle_loop_action = SKAction.customAction(withDuration: 0, actionBlock: {
                _, _ in self.update_xaxis(bottom_mask_node: bottom_mask_node, curve_node: curve_node)
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
            let mask_node = SKSpriteNode(texture: nil, color:  SKColor.black, size: full_size)
            mask_node.anchorPoint = CGPoint(x: 0, y: 0)

            if !debug { crop_node.maskNode = mask_node }
            root_node = crop_node
            self.addChild(root_node)
        } else { root_node = self }

        root_node.addChild(grid_node)
        if subgrid_node != nil { grid_node.addChild(subgrid_node!) }
        grid_node.addChild(curve_node)
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
    
    private func update_xaxis(bottom_mask_node: SKSpriteNode, curve_node: SKShapeNode) {
        right_display_date.addTimeInterval(grid_time_interval)

        // Move curve to the left
        curve_node.position.x -= grid_size.width

        // Move date nodes to the left
        bottom_mask_node.enumerateChildNodes(withName: "//date-*", using: {
            node, _ in node.position.x -= self.grid_size.width
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
            node.date!.addTimeInterval(TimeInterval(TimeInterval(1 + ((rightmost_node!.position.x - leftmost_node!.position.x) / grid_size.width)) * grid_time_interval))
            node.position.x = rightmost_node!.position.x + grid_size.width
        }
    }
    
    public func newData(manager: TimeSeries, value: TimeSeriesElement) {
        
    }
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

