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

final class GenericTools : AutoTrace {
    // holding strong refs to tap targets
    static var tap_manager: [ManageTap] = []

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

    // split a view controller with two columns of same width
    static func splitViewControllerSameWidth(_ svc: UISplitViewController) {
        svc.preferredDisplayMode = .allVisible
        svc.minimumPrimaryColumnWidth = 0
        svc.maximumPrimaryColumnWidth = CGFloat.greatestFiniteMagnitude
        svc.preferredPrimaryColumnWidthFraction = 0.5
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
        
        // retrieve the cube node
        let ship = scene.rootNode.childNode(withName: "box", recursively: true)!
        
        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 10)))
        
        // set the scene to the view
        view.scene = scene
        
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        view.showsStatistics = true
        
        // configure the view
        view.backgroundColor = UIColor.black
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
        let manageTap = ManageTap(view)
        // create a strong ref to the target
        tap_manager.append(manageTap)
        let tapGesture = UITapGestureRecognizer(target: manageTap, action: #selector(manageTap.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
}

// manage a tap on a demo ship scene view
class ManageTap {
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

protocol AutoTrace {
}

extension AutoTrace {
    
}
