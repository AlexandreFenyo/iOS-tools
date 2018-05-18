//
//  GenericTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// "alt" means "alternative"

// read plist: defaults read /Users/fenyo/Library/Developer/Xcode/DerivedData/iOS_tools-epwocfsynihtagcdtrgfzhdwlvrf/Build/Products/Debug-iphoneos/iOS\ tools.app/Info.plist

import Foundation
import UIKit
import QuartzCore
import SceneKit
import SpriteKit

extension String {
    // Substring starting at start with count chars
    func sub(_ start: Int, _ count: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: start)..<self.index(self.startIndex, offsetBy: start + count - 1)])
    }
    
    // Substring starting at start
    func sub(_ start: Int) -> String {
        return sub(start, self.count - start)
    }
}

final class GenericTools : AutoTrace {
    // holding strong refs to tap targets
    static var tap_demo_ship_manager: [ManageTapDemoShip] = []

    // holding strong refs to tap cube targets
    static var tap_cube_manager: [ManageTapCube] = []
    
    static var alternate_value = true

    // extract configuration parameters
    static let must_log = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "log") ?? false) as! Bool
    static let must_call_initial_tests = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "must call initial tests") ?? false) as! Bool
    static let must_create_demo_ship_scene = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "must create demo ship scene") ?? false) as! Bool

    // Basic debugging
    // Can be declared these ways:
    // static func here() -> () {
    // static func here() -> Void {
    // static func here() {
    static func here() {
        if !must_log { return }
        print("here");
    }

    // Basic debugging
    // ex.: here("here")
    //      here("here", self)
    static func here(_ s: String, _ o: Any? = nil) {
        if !must_log { return }
        if o == nil {
            print("here:", s);
        } else {
            // print(o.debugDescription) prints the instance as an Optional
            // print(o!.debugDescription) does not compile ("Value of type 'Any' has no member 'debugDescription'")
            print("here: ", o!, ":", s, separator: String() /* alt: separator: "" */)
        }
    }
    
    // The previous function can also we written with o as an implicitely unwrapped Optional wrapping an instance of Any? (Any?!), like this:
    // static func here(_ s: String, _ o: Any?! = nil) {
    // ...
    // print("here:", s, "instance:", o)
    // ...

    // Placeholder for tests
    static func test() {
    }

    // Espace insécable
    static func insec() -> String {
        let arr: [UInt8] = [ 0xC2, 0xA0 ]
        return NSString(bytes: arr, length: arr.count, encoding: String.Encoding.utf8.rawValue)! as String
    }

    // split a view controller with two columns of same width
    static func splitViewControllerSameWidth(_ svc: UISplitViewController) {
        svc.preferredDisplayMode = .allVisible
        svc.minimumPrimaryColumnWidth = 0
        svc.maximumPrimaryColumnWidth = CGFloat.greatestFiniteMagnitude
        svc.preferredPrimaryColumnWidthFraction = 0.5
    }

    // créer un alternate() indexé sur une chaîne de caractères
    static func alternate() -> Bool {
        alternate_value = !alternate_value
        return alternate_value
    }

    static func createScene(_ view: UIView) {
        if !alternate() { createSpriteScene(view as! SKView) }
        else { createCubeScene(view as! SCNView) }
    }
    
    static func createSpriteScene(_ view: SKView) {
        // Create a scene
//        let scene = SKScene(size: view.frame.size)
        let scene = SKScene(size: CGSize(width: view.frame.size.width / 2, height: view.frame.size.height))
        scene.backgroundColor = SKColor.white
        view.presentScene(scene)

        // XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        // Add a chart on the 2D left pane

        let chart_node = SKChartNode(size: CGSize(width: 410, height: 300), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 60, bottom_height: 50, vertical_unit: "Kbit/s", vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, debug: true)
        scene.addChild(chart_node)
        chart_node.position = CGPoint(x: 50, y: 100)

        // Display debug informations
        view.showsFPS = true
        view.showsQuadCount = true
    }
    
    // Insert the demo cube scene into a view
    static func createCubeScene(_ view: SCNView) {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/Cube.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        
        // retrieve the cube node
        let box_node = scene.rootNode.childNode(withName: "box", recursively: true)!
//        box_node.geometry?.firstMaterial?.transparency = 0
        
        // add a box to draw a line on one of its faces
        let box2_geom = SCNBox(width: 2.5, height: 0.5, length: 0.5, chamferRadius: 0.0)
//        box2_geom.firstMaterial?.transparency = 0
        let box2_node = SCNNode(geometry: box2_geom)
        box_node.addChildNode(box2_node)

        // draw a line
        var vertices = [SCNVector3]()
        vertices.append(SCNVector3Make(0, 0, 0.5))
        vertices.append(SCNVector3Make(0, 0, 1))
        let geo_src = SCNGeometrySource(vertices: vertices)
        let indices : [Int32] = [0, 1]
        let geo_elem = SCNGeometryElement(indices: indices, primitiveType: SCNGeometryPrimitiveType.line)
        let geo = SCNGeometry(sources: [ geo_src ], elements: [ geo_elem ])
        geo.firstMaterial?.isDoubleSided = true
        let n = SCNNode(geometry: geo)
        box_node.addChildNode(n)

        // wireframe
        // XXX trouver comment faire avec cette syntaxe : view.debugOptions = .renderAsWireframe
        view.debugOptions.insert(SCNDebugOptions.showWireframe)
        // does not work, so we set material transparency to 0
        // view.debugOptions.insert(SCNDebugOptions.renderAsWireframe)
        
        
        // animate the 3d object
        box_node.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 10)))

        // set the scene to the view
        view.scene = scene
        
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        view.showsStatistics = true

        // configure the view
        view.backgroundColor = UIColor.black
     
        // add a tap gesture recognizer
        let manage_tap = ManageTapCube(view)
        // create a strong ref to the target
        tap_cube_manager.append(manage_tap)
        let tapGesture = UITapGestureRecognizer(target: manage_tap, action: #selector(ManageTapCube.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

//        let plane_node = SCNChartNode(density: 1000, size: CGSize(width: 4000, height: 3000), grid_size: CGSize(width: 200, height: 200), subgrid_size: CGSize(width: 200 / 5, height: 200 / 5), line_width: 5, left_width: 600, bottom_height: 500, vertical_unit: "Kbit/s", vertical_cost: 10, date: Date(), time_align: 5, grid_time_interval: 10, background: .gray, debug: false)
        let plane_node = SCNChartNode(density: 450, size: CGSize(width: 800, height: 600), grid_size: CGSize(width: 800 / 5, height: 800 / 5), subgrid_size: CGSize(width: 800 / 5 / 4, height: 800 / 5 / 4), line_width: 5, left_width: 50, bottom_height: 150, vertical_unit: "Kbit/s", vertical_cost: 10, date: Date(), grid_time_interval: 10, background: .gray, font_size_ratio: 0.15, debug: true)
        scene.rootNode.addChildNode(plane_node)

    }
    
    // Insert the demo ship scene into a view
    static func createDemoShipScene(_ view: SCNView) {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!

        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // set the scene to the view
        view.scene = scene
        
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        view.showsStatistics = true
        
        // configure the view
        view.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let manageTap = ManageTapDemoShip(view)
        // create a strong ref to the target
        tap_demo_ship_manager.append(manageTap)
        let tapGesture = UITapGestureRecognizer(target: manageTap, action: #selector(manageTap.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
}

// manage a tap on a demo ship scene view
class ManageTapDemoShip {
    let scnView: SCNView

    init(_ v: SCNView) {
        self.scnView = v
    }

    // Callback used by createDemoShipScene()
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]

            // get its material
            let material = result.node.geometry!.firstMaterial!

            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5

            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5

                material.emission.contents = UIColor.black

                SCNTransaction.commit()
            }

            material.emission.contents = UIColor.red

            SCNTransaction.commit()
        }
    }
}

// manage a tap on a Cube scene view
class ManageTapCube {
    let scnView: SCNView
    
    init(_ v: SCNView) {
        self.scnView = v
    }
    
    // Callback used by createDemoShipScene()
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            GenericTools.here()
            
            // highlight it
//            SCNTransaction.begin()
//            scnView.debugOptions.insert(SCNDebugOptions.showWireframe)
//            scnView.debugOptions.insert(SCNDebugOptions.renderAsWireframe)
//            SCNTransaction.commit()
    }
}

protocol AutoTrace {
}

extension AutoTrace {
    
}
