//
//  Chart.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 11/05/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// 3D nodes hierarchy
// chart: SCNChartNode (SCNNode)
//   .geometry: SCNPlane
//   .contents: chart_scene
// chart_scene: SKScene
//   chart_node == root_node: SKChartNode (SKSpriteNode)
//     grid_node: SKShapeNode
//       subgrid_node: SKShapeNode
//       bottom_mask: SKSpriteNode
//         [bottom_label_node]: SKExtLabelNode (SKLabelNode)
//         [hyphen_node]: SKSpriteNode
//       curve_node: SKShapeNode
//         curve_marker: SKNode
//         [point_node]: SKShapeNode
//         triangle_node: SKShapeNode
//           max_label: SKLabelNode
//     left_mask_node: SKSpriteNode
//       [left_label_node]: SKLabelNode
//       [hyphen_node]: SKSpriteNode

// 2D nodes hierarchy
// chart: SKChartNode (SKSpriteNode)
//   crop_node == root_node: SKCropNode
//     .mask: mask_node: SKSpriteNode
//     grid_node: SKShapeNode
//       subgrid_node: SKShapeNode
//       bottom_mask: SKSpriteNode
//         [bottom_label_node]: SKExtLabelNode (SKLabelNode)
//         [hyphen_node]: SKSpriteNode
//       curve_node: SKShapeNode
//         curve_marker: SKNode
//         [point_node]: SKShapeNode
//         triangle_node: SKShapeNode
//           max_label: SKLabelNode
//     left_mask_node: SKSpriteNode
//       [left_label_node]: SKLabelNode
//       [hyphen_node]: SKSpriteNode

import Foundation
import UIKit
import QuartzCore
import SceneKit
import SpriteKit

// Default values
struct ChartDefaults {
    // See http://iosfonts.com
    static let font_name = "Arial Rounded MT Bold"
    // If ratio == 1, there is no space between lines of text
    static let horizontal_font_size_ratio : CGFloat = 0.5
    static let vertical_font_size_ratio : CGFloat = 0.5
    static let font_color = SKColor(red: 0.7, green: 0, blue: 0, alpha: 1)
    static let optimal_vertical_resolution_ratio : CGFloat = 1.2
    static let vertical_transition_duration : Double = 1
    static let minimum_highest : Float = 1
    // Set to true to avoid moving left at start
    static let debug_do_not_move = false
}

enum PositionRelativeToScreen {
    case onLeft
    case onScreen
    case onRight
}

enum ChartPositionMode {
    case manual
    case followDate
}

// A Label Node with additional attributes
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
    public var chart_node: SKChartNode?
    
    public init(ts: TimeSeries, density: CGFloat, full_size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, vertical_unit: String, grid_vertical_cost: Float, date: Date, grid_time_interval: TimeInterval, background: SKColor = .clear, font_name: String = ChartDefaults.font_name, max_horizontal_font_size: CGFloat? = nil, max_vertical_font_size: CGFloat? = nil, horizontal_font_size_ratio: CGFloat = ChartDefaults.horizontal_font_size_ratio, vertical_font_size_ratio: CGFloat = ChartDefaults.vertical_font_size_ratio, font_color: SKColor = ChartDefaults.font_color, spline: Bool = true, vertical_auto_layout: Bool = true, mode: ChartPositionMode = .followDate, debug: Bool = true) {
        super.init()

        // Create a 2D scene
        let chart_scene = SKScene(size: full_size)
        chart_scene.backgroundColor = .white

        // Create a 3D plan containing the 2D scene
        self.geometry = SCNPlane(width: full_size.width / density, height: full_size.height / density)
        self.geometry?.firstMaterial?.isDoubleSided = true
        self.geometry?.firstMaterial?.diffuse.contents = chart_scene

        // Create a 2D chart and add it to the scene
        // Note: cropping this way does not seem to work in a 3D env with GL instead of Metal (ex.: Hackintosh running on esx-i)
        chart_node = SKChartNode(ts: ts, full_size: full_size, grid_size: grid_size, subgrid_size: subgrid_size, line_width: line_width, left_width: left_width, bottom_height: bottom_height, vertical_unit: vertical_unit, grid_vertical_cost: grid_vertical_cost, date: date, grid_time_interval: grid_time_interval, crop: false, background: background, font_name: font_name, max_horizontal_font_size: max_horizontal_font_size, max_vertical_font_size: max_vertical_font_size, horizontal_font_size_ratio: horizontal_font_size_ratio, vertical_font_size_ratio: vertical_font_size_ratio, font_color: font_color, spline: spline, vertical_auto_layout: vertical_auto_layout, mode: mode, debug: debug)
        chart_node!.anchorPoint = CGPoint(x: 0, y: 0)
        chart_scene.addChild(chart_node!)

        self.scale = SCNVector3(x: 1, y: -1, z: 1)
    }
    
    public func registerGestureRecognizers(view: UIView) {
            chart_node!.registerGestureRecognizers(view: view)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKChartNode : SKSpriteNode, TimeSeriesReceiver {
    private var debug: Bool
    private let spline: Bool
    private let vertical_auto_layout: Bool
    
    private var highest : Float = 0

    private var root_node : SKNode?
    
    // State variables
    private var full_size: CGSize
    private var grid_size: CGSize
    private var left_width: CGFloat
    private var bottom_height: CGFloat
    private var grid_time_interval: TimeInterval
    private var grid_vertical_cost: Float?
    private var grid_vertical_factor: Int?
    private var ts: TimeSeries
    private var vertical_unit: String
    private var line_width: CGFloat
    private var subgrid_size: CGSize?
    private var background: SKColor
    private var font_name: String
    private var max_horizontal_font_size: CGFloat?
    private var max_vertical_font_size: CGFloat?
    private var horizontal_font_size_ratio: CGFloat
    private var vertical_font_size_ratio: CGFloat
    private var font_color: SKColor
    private var crop: Bool
    private var mode: ChartPositionMode
    private var current_date: Date

    // Properties computed from state variables
    private var graph_width : CGFloat?
    private var graph_height : CGFloat?
    private var grid_full_width: CGFloat?
    private var grid_full_height: CGFloat?
    // Right-most displayed grid column width
    private var horizontal_remainder: CGFloat?

    // Graphic components
    private var grid_node : SKShapeNode?
    private var curve_node : SKShapeNode?
    private var curve_marker : SKNode?
    private var curve_marker_date : Date?
    private var bottom_mask_node : SKSpriteNode?
    private var left_mask_node : SKSpriteNode?

    public func testDebug() {
    }
    
    // Update properties derivated from state
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

    // Projection of a time series element into the curve coordinates system
    private func toPoint(tse: TimeSeriesElement) -> CGPoint {
        return CGPoint(x: curve_marker!.position.x + CGFloat(tse.date.timeIntervalSince(curve_marker_date!) / grid_time_interval) * grid_size.width, y: CGFloat(tse.value / grid_vertical_cost!) * grid_size.height)
    }

    // Check that a point is not hidden
    private func isCurvePointOnScreen(point: CGPoint) -> Bool {
        let p = grid_node!.convert(point, from: curve_node!)
        return p.x >= 0 && p.x <= grid_full_width!
    }

    // Check that a point is not hidden
    private func isCurvePointOnScreen(tse: TimeSeriesElement) -> Bool {
        return isCurvePointOnScreen(point: toPoint(tse: tse))
    }

    // Check that a segment is not hidden
    private func isCurveSegmentOnScreen(from: CGPoint, to: CGPoint) -> Bool {
        return positionRelativeToScreen(point: from) == .onScreen || positionRelativeToScreen(point: to) == .onScreen || positionRelativeToScreen(point: from) != positionRelativeToScreen(point: to)
    }

    // Check that a segment is not hidden
    private func isCurveSegmentOnScreen(from: TimeSeriesElement, to: TimeSeriesElement) -> Bool {
        return isCurveSegmentOnScreen(from: toPoint(tse: from), to: toPoint(tse: to))
    }

    // Position of a curve point relative to screen
    private func positionRelativeToScreen(point: CGPoint) -> PositionRelativeToScreen {
        let p = grid_node!.convert(point, from: curve_node!)
        if p.x < 0 { return .onLeft }
        if p.x > grid_full_width! { return .onRight }
        return .onScreen
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
    public init(ts: TimeSeries, full_size: CGSize, grid_size: CGSize, subgrid_size: CGSize? = nil, line_width: CGFloat, left_width: CGFloat = 0, bottom_height: CGFloat = 0, vertical_unit: String, grid_vertical_cost: Float, date: Date, grid_time_interval: TimeInterval, crop: Bool = true, background: SKColor = .clear, font_name: String = ChartDefaults.font_name, max_horizontal_font_size: CGFloat? = nil, max_vertical_font_size: CGFloat? = nil, horizontal_font_size_ratio: CGFloat = ChartDefaults.horizontal_font_size_ratio, vertical_font_size_ratio: CGFloat = ChartDefaults.vertical_font_size_ratio, font_color: SKColor = ChartDefaults.font_color, spline: Bool = true, vertical_auto_layout: Bool = true, mode: ChartPositionMode = .followDate, debug: Bool = true) {
        self.debug = debug
        self.spline = spline
        self.vertical_auto_layout = vertical_auto_layout
        self.crop = crop

        // Save state
        self.ts = ts
        self.full_size = full_size
        self.grid_size = grid_size
        self.left_width = left_width
        self.bottom_height = bottom_height
        self.grid_time_interval = grid_time_interval
        self.grid_vertical_cost = grid_vertical_cost
        self.vertical_unit = vertical_unit
        self.line_width = line_width
        self.subgrid_size = subgrid_size
        self.background = background
        self.font_name = font_name
        self.max_horizontal_font_size = max_horizontal_font_size
        self.max_vertical_font_size = max_vertical_font_size
        self.horizontal_font_size_ratio = horizontal_font_size_ratio
        self.vertical_font_size_ratio = vertical_font_size_ratio
        self.font_color = font_color
        self.mode = mode
        self.current_date = date

        // Create self
        super.init(texture: nil, color: debug ? .cyan : background, size: full_size)
        updateStateVariables()
        self.anchorPoint = CGPoint(x: 0, y: 0)
        ts.register(self)

        // Crop the drawing when working in a 2D scene
        if crop {
            let crop_node = SKCropNode()
            let mask_node = SKSpriteNode(texture: nil, color: .black, size: full_size)
            mask_node.anchorPoint = CGPoint(x: 0, y: 0)

            if !debug { crop_node.maskNode = mask_node }
            root_node = crop_node
            self.addChild(root_node!)
        } else { root_node = self }
        
        // Create chart components
        var max_val : Float = 0
        for elt in ts.getElements() { max_val = max(max_val, elt.value) }
        createChartComponents(date: mode == .followDate ? Date() : current_date, max_val: max_val)
        drawCurve(ts: ts)
    }

    // Update displayed dates
    private func updateXaxis(bottom_mask_node: SKSpriteNode, curve_node: SKShapeNode) {
        // Move date nodes to the left
        bottom_mask_node.enumerateChildNodes(withName: "//date-*") { node, _ in node.position.x -= self.grid_size.width }

        // Find both extreme date nodes
        var leftmost_node : SKNode?
        var rightmost_node : SKNode?
        bottom_mask_node.enumerateChildNodes(withName: "//date-*") {
            node, _ in

            if let posx = leftmost_node?.position.x {
                if node.position.x < posx { leftmost_node = node }
            } else { leftmost_node = node }

            if let posx = rightmost_node?.position.x {
                if node.position.x > posx { rightmost_node = node }
            } else { rightmost_node = node }
        }

        // Set the left-most node to the right of the right-most node
        if leftmost_node != nil && rightmost_node != nil {
            let node = leftmost_node! as! SKExtLabelNode
            node.date!.addTimeInterval(TimeInterval(TimeInterval(1 + ((rightmost_node!.position.x - leftmost_node!.position.x) / grid_size.width)) * grid_time_interval))
            node.position.x = rightmost_node!.position.x + grid_size.width
        }
    }

    // Display only segments or points that can be viewed
    private func drawCurve(ts: TimeSeries) {
        if hasActions() { return }
        
        let computePoints: () -> ([CGPoint], Float, TimeSeriesElement?) = {
            var highest : Float = ChartDefaults.minimum_highest
            var highest_elt : TimeSeriesElement?
            // Points from segments that are partly or totally displayed
            var points: [CGPoint] = [ ]
            let elts = ts.getElements()
            if elts.count == 1 {
                // There is no segment, only one point
                if self.isCurvePointOnScreen(tse: elts[0]) {
                    let point = self.toPoint(tse: elts[0])
                    if (highest < elts[0].value) {
                        highest_elt = elts[0]
                        highest = elts[0].value
                    }
                    points.append(point)
                }
            } else if elts.count > 1 {
                // Convert coordinates
                var all_points: [CGPoint] = [ ]
                for elt in elts { all_points.append(self.toPoint(tse: elt)) }
                for i in all_points.indices.dropFirst() {
                    if self.isCurveSegmentOnScreen(from: all_points[i - 1], to: all_points[i]) {
                        // This is the last segment and it is partly or totally displayed
                        points.append(all_points[i - 1])
                        if i == all_points.count - 1 { points.append(all_points[i]) }
                        let foo = self.grid_vertical_cost! * Float(all_points[i - 1].y / self.grid_size.height)
                        let bar = self.grid_vertical_cost! * Float(all_points[i].y / self.grid_size.height)
                        if highest < foo {
                            highest = foo
                            highest_elt = elts[i - 1]
                        }
                        if highest < bar {
                            highest = bar
                            highest_elt = elts[i]
                        }
                    }
                }
            }
            return (points, highest, highest_elt)
        }

        let drawPoints: (inout [CGPoint], TimeSeriesElement?) -> () = {
            (points, highest_tse) in
            // Draw curve
            if self.spline { self.curve_node!.path = SKShapeNode(splinePoints: &points, count: points.count).path }
            else { self.curve_node!.path = SKShapeNode(points: &points, count: points.count).path }

            // Add points
            self.curve_node?.removeAllChildren()
            let point_radius = self.line_width * 3
            for point in points {
                let point_node = SKShapeNode(circleOfRadius: point_radius)
                point_node.fillColor = .black
                point_node.strokeColor = .red
                point_node.lineWidth = self.line_width
                self.curve_node?.addChild(point_node)
                point_node.position = CGPoint(x: point.x, y: point.y)
            }

            if highest_tse != nil {
                let highest_point = self.toPoint(tse: highest_tse!)

                // Create blinking triangle
                let sqrt_3_div_2 : CGFloat = 0.87
                let triangle_width = 2 * self.line_width * 5
                let triangle_height = triangle_width * sqrt_3_div_2
                var points = [CGPoint(x: 0, y: 0),
                              CGPoint(x: -triangle_width / 2, y: triangle_height),
                              CGPoint(x: triangle_width / 2, y: triangle_height),
                              CGPoint(x: 0, y: 0)]
                let triangle_node = SKShapeNode(points: &points, count: points.count)
                triangle_node.lineWidth = self.line_width * 1.5
                triangle_node.strokeColor = .yellow
                self.curve_node?.addChild(triangle_node)
                let triangle_relative_height = point_radius * 2
                triangle_node.position = CGPoint(x: highest_point.x, y: highest_point.y + triangle_relative_height)
                triangle_node.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeIn(withDuration: 0.3), SKAction.fadeOut(withDuration: 0.3)])))

                // Add corresponding value under triangle
                let max_label = SKLabelNode(fontNamed: self.font_name)
                max_label.text = String(Int(highest_tse!.value))
                if max_label.text!.count > self.grid_vertical_factor! { max_label.text! = max_label.text!.sub(0, max_label.text!.count - self.grid_vertical_factor!) }

                max_label.fontSize = triangle_height
                max_label.fontColor = .yellow
                max_label.horizontalAlignmentMode = .center
                max_label.verticalAlignmentMode = .top
                triangle_node.addChild(max_label)
                max_label.position = CGPoint(x: 0, y: -triangle_relative_height * 2)
            }
        }

        var (points, target_h, tse) = computePoints()

        if highest != target_h {
            var start_height = highest
            
            var runnable: ((SKNode, CGFloat) -> ())?
            runnable = {
                (node, t) in
                self.createChartComponents(date: self.mode == .followDate ? Date() : self.current_date, max_val: Float(start_height) + (target_h - Float(start_height)) * Float(t) / Float(ChartDefaults.vertical_transition_duration))
                let check_h : Float
                (points, check_h, tse) = computePoints()
                drawPoints(&points, tse)
                if check_h != target_h {
                    self.removeAllActions()
                    start_height = self.highest
                    target_h = check_h
                    self.run(SKAction.customAction(withDuration: ChartDefaults.vertical_transition_duration, actionBlock: runnable!))
                }
            }
            run(SKAction.customAction(withDuration: ChartDefaults.vertical_transition_duration, actionBlock: runnable!))
        } else { drawPoints(&points, tse) }
    }

    // Create or update chart components
    private func createChartComponents(date: Date, max_val: Float) {
        // Update state
        highest = max_val

        // Remove curve
        curve_node?.removeAllChildren()
        
        // Remove displayed dates and associated hyphens
        bottom_mask_node?.removeAllChildren()
        
        // Remove animations
        grid_node?.removeAllActions()
        
        // Remove bottom_mask_node, curve_node and subgrid_node
        grid_node?.removeAllChildren()
        
        // Remove grid_node, left_mask_node and associated hyphens
        root_node?.removeAllChildren()
        
        if vertical_auto_layout {
            let (_grid_height, _cost, _unit, _factor) = SKChartNode.getOptimizedVerticalParameters(height: graph_height!, max_val: max_val, nlines: 5)
            
            grid_size.height = _grid_height
            subgrid_size?.height = grid_size.height / 5.0
            vertical_unit = _unit
            grid_vertical_cost = _cost
            grid_vertical_factor = _factor

            updateStateVariables()
        }
        
        assert(grid_size.width <= full_size.width - left_width)
        assert(grid_size.height <= full_size.height - bottom_height)
        assert(subgrid_size != nil ? grid_size.width.truncatingRemainder(dividingBy: subgrid_size!.width) == 0 : true)
        if !vertical_auto_layout { assert(subgrid_size != nil ? grid_size.height.truncatingRemainder(dividingBy: subgrid_size!.height) == 0 : true) }
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
        grid_node = SKShapeNode(path: grid_path)
        grid_node!.path = grid_path
        grid_node!.strokeColor = .red
        grid_node!.lineWidth = line_width

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
            subgrid_node?.strokeColor = .red
            // In order to avoid flickering on black or dark background, linewidth must be greater than 1
            subgrid_node?.lineWidth = line_width
            subgrid_node?.alpha = 0.3
        } else {
            subgrid_node = nil
        }

        // Add left mask
        left_mask_node = SKSpriteNode(color: debug ? .blue : background, size: CGSize(width: left_width, height: full_size.height))
        left_mask_node!.anchorPoint = CGPoint(x: 0, y: 0)
        if debug { left_mask_node!.alpha = 0.5 }
        // left_mask_node must be higher than bottom_mask
        left_mask_node!.zPosition = 2

        // Instanciate font to get informations about it
        // font.pointSize is set to size parameter - it can be set to any value since we compute the size using font.pointSize
        let font = UIFont(name: font_name, size: 2) ?? UIFont.preferredFont(forTextStyle: .body)

        // Create y-axis values
        y = 0
        while y <= graph_height! {
            // Add quantity
            let left_label_node = SKLabelNode(fontNamed: font_name)
            left_label_node.text = String(Int(grid_vertical_cost! * Float(y / grid_size.height)))
            if left_label_node.text!.count > grid_vertical_factor! { left_label_node.text = left_label_node.text!.sub(0, left_label_node.text!.count - grid_vertical_factor!) }
            left_label_node.text! += " " + vertical_unit
            left_label_node.fontSize = vertical_font_size_ratio * grid_size.height / font.capHeight * font.pointSize
            // Help select correct font size
            if debug { print("vertical fontsize:", left_label_node.fontSize)}
            if !debug && max_vertical_font_size != nil && left_label_node.fontSize > max_vertical_font_size! { left_label_node.fontSize = max_vertical_font_size! }

            left_label_node.fontColor = font_color
            left_label_node.horizontalAlignmentMode = .right
            left_mask_node!.addChild(left_label_node)
            left_label_node.position = CGPoint(x: left_width - left_label_node.fontSize / 2, y: y + bottom_height - 0.7 * left_label_node.fontSize / 2)

            // Add hyphen
            let hyphen_node = SKSpriteNode(color: grid_node!.strokeColor, size: CGSize(width: left_label_node.fontSize / 4, height: grid_node!.lineWidth))
            hyphen_node.anchorPoint = CGPoint(x: 1, y: 0.5)
            left_mask_node!.addChild(hyphen_node)
            hyphen_node.position = CGPoint(x: left_width, y: y + bottom_height)

            y += grid_size.height
        }

        // Add bottom mask
        bottom_mask_node = SKSpriteNode(color: debug ? .blue : background, size: CGSize(width: grid_full_width!, height: bottom_height))
        bottom_mask_node!.anchorPoint = CGPoint(x: 0, y: 1)
        if debug { bottom_mask_node!.alpha = 1 }
        // bottom_mask must be higher than (in front of) the curve
        bottom_mask_node!.zPosition = 1
        
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
            grid_node!.position = CGPoint(x: left_width - (horizontal_time_offset - horizontal_remainder!), y: bottom_height)
            current_date = date_rounded.addingTimeInterval(grid_time_interval * 2)
        } else {
            grid_node!.position = CGPoint(x: left_width + (horizontal_remainder! - horizontal_time_offset) - grid_size.width, y: bottom_height)
            current_date = date_rounded.addingTimeInterval(grid_time_interval)
        }

        while x >= 0 {
            // Add date
            let bottom_label_node = SKExtLabelNode(fontNamed: font_name, date: current_date)
            bottom_label_node.verticalAlignmentMode = .top
            bottom_label_node.horizontalAlignmentMode = .left

            bottom_label_node.zRotation = -CGFloat.pi / 4
            bottom_label_node.fontSize = horizontal_font_size_ratio * grid_size.width / font.capHeight * font.pointSize
            // Help select correct font size
            if debug { print("horizontal fontsize:", bottom_label_node.fontSize)}
            if !debug && max_horizontal_font_size != nil && bottom_label_node.fontSize > max_horizontal_font_size! { bottom_label_node.fontSize = max_horizontal_font_size! }
            bottom_label_node.fontColor = font_color
            bottom_mask_node!.addChild(bottom_label_node)
            bottom_label_node.position = CGPoint(x: x, y: -bottom_label_node.fontSize / 2)
            bottom_label_node.name = "date-" + String(date_rounded.timeIntervalSince1970)

            // Add hyphen
            let hyphen_node = SKSpriteNode(color: grid_node!.strokeColor, size: CGSize(width: grid_node!.lineWidth, height: bottom_label_node.fontSize / 4))
            hyphen_node.anchorPoint = CGPoint(x: 0.5, y: 1)
            bottom_mask_node!.addChild(hyphen_node)
            hyphen_node.position = CGPoint(x: x, y: 0)

            x -= grid_size.width
            current_date.addTimeInterval(-grid_time_interval)
        }

        // Add curve
        curve_node = SKShapeNode()

        // Add marker to be able to make a projection of a date into the curve coordinates system
        curve_marker = SKNode()
        curve_marker_date = date
        curve_node!.addChild(curve_marker!)
        curve_marker!.position.x = left_width - grid_node!.position.x + graph_width!

        // Initialize curve
        curve_node!.lineWidth = line_width
        curve_node!.strokeColor = .black

        // Animate
        if (mode == .followDate) {
            func getOperations(after: TimeInterval) -> () -> () {
                return {
                    self.grid_node!.position.x += self.grid_size.width
                    self.curve_node!.position.x -= self.grid_size.width
                    self.updateXaxis(bottom_mask_node: self.bottom_mask_node!, curve_node: self.curve_node!)
                    self.drawCurve(ts: self.ts)
                }
            }
            // Launch animation
            let first_move_left_action = SKAction.moveBy(x: -(grid_size.width - (left_width - grid_node!.position.x)), y: 0, duration: grid_time_interval * TimeInterval(((grid_size.width - (left_width - grid_node!.position.x)) / grid_size.width)))
            if !ChartDefaults.debug_do_not_move {
                grid_node!.run(first_move_left_action) {
                    getOperations(after: first_move_left_action.duration)()
                    let move_left_action = SKAction.moveBy(x: -self.grid_size.width, y: 0, duration: self.grid_time_interval)
                    let move_right_action = SKAction.run(getOperations(after: move_left_action.duration))
                    let sequence_action = SKAction.sequence([move_left_action, move_right_action])
                    let loop_action = SKAction.repeatForever(sequence_action)
                    self.grid_node!.run(loop_action)
                }
            }
        }

        root_node!.addChild(grid_node!)
        if subgrid_node != nil { grid_node!.addChild(subgrid_node!) }
        root_node!.addChild(left_mask_node!)

        grid_node!.addChild(bottom_mask_node!)
        grid_node!.addChild(curve_node!)
    }

    public func cbNewData(ts: TimeSeries, tse: TimeSeriesElement) {
        drawCurve(ts: ts)
    }

    // Compute best vertical parameters
    // input:
    // - height
    // - value at height
    // - max number of horizontal lines
    // output:
    // - grid_size.height
    // - grid_vertical_cost
    // - vertical_unit
    // - factor
    public static func getOptimizedVerticalParameters(height: CGFloat, max_val: Float, nlines: Int) -> (CGFloat, Float, String, Int) {
        var max_val = max_val
        max_val *= Float(ChartDefaults.optimal_vertical_resolution_ratio)
        if max_val < Float(nlines) { max_val = Float(nlines) }

        let first_label = String(Int((max_val / Float(nlines)).rounded(.down)))
        var left_digit = first_label.sub(0, 1)
        switch left_digit {
        case "3", "4":
            left_digit = "2"
        case "6", "7", "8", "9":
            left_digit = "5"
        default:
            break
        }
        let (unit, factor) : (String, Int) = {
            if first_label.count < 4 { return ("bit/s", 0) }
            if first_label.count < 7 { return ("Kbit/s", 3) }
            if first_label.count < 10 { return ("Mbit/s", 6) }
            return ("Gbit/s", 9)
        }()
        let grid_vertical_cost = Float(Int(left_digit + String(repeating: "0", count: first_label.count - 1))!)
        return (height * CGFloat(grid_vertical_cost / max_val), grid_vertical_cost, unit, factor)
    }

    public func registerGestureRecognizers(view: UIView) {
        // This creates a strong ref to the target
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SKChartNode.handleTap(_:))))
        // This creates a strong ref to the target
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(SKChartNode.handlePan(_:))))
    }
    
    @objc
    func handleTap(_ gesture_recognize: UITapGestureRecognizer) {
        print("HANDLE TAP")
    }

    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        print("HANDLE PAN")
        
        if gesture.state == .began {
            mode = .manual
            let point = gesture.translation(in: gesture.view!)
            print("began", point.x, point.y)
        }

        if gesture.state == .changed {
            print("changed")
            let point = gesture.translation(in: gesture.view!)
            print("changed", point.x, point.y)
        }
        
//        createChartComponents(date: Date(), max_val: highest)
//        drawCurve(ts: ts)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

