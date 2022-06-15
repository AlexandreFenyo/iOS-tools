//
//  GenericTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// https://www.raywenderlich.com/173753/uisplitviewcontroller-tutorial-getting-started-2

// "alt" means "alternative"

// read plist: defaults read /Users/fenyo/Library/Developer/Xcode/DerivedData/iOS_tools-epwocfsynihtagcdtrgfzhdwlvrf/Build/Products/Debug-iphoneos/iOS\ tools.app/Info.plist

// UI: https://developer.apple.com/ios/human-interface-guidelines/overview/themes/
//     https://developer.apple.com/library/content/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html#//apple_ref/doc/uid/TP40015214-CH2-SW1
//     https://www.raywenderlich.com/160521/storyboards-tutorial-ios-11-part-1
//     google ios storyboard UI
//     bouquin Kindle

import Foundation
import UIKit
import QuartzCore
import SceneKit
import SpriteKit

// Useful declaration to get definitions of Swift (right-click / "Jump to definition")
import Swift

extension String {
    // Substring starting at start with count chars
    func sub(_ start: Int, _ count: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: start)..<self.index(self.startIndex, offsetBy: start + count)])
    }

    // Substring starting at start
    func sub(_ start: Int) -> String {
        return sub(start, self.count - start)
    }
}

final class GenericTools : AutoTrace {
    public static var plane_node : SCNChartNode?
    public static var chart_node : SKChartNode?
    
    // holding strong refs to tap targets
    private static var tap_demo_ship_manager: [ManageTapDemoShip] = []

    // holding strong refs to tap cube targets
    private static var tap_cube_manager: [ManageTapCube] = []
    
    private static var alternate_value = true

    public static let ts = TimeSeries()
    
    public static let test_date : Date = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-mm-yyyy HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        let date = dateFormatter.date(from: "01-01-2017 18:00:16")?.addingTimeInterval(TimeInterval(0))
        return date!
    }()

    // extract configuration parameters
    public static let must_log = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "log") ?? false) as! Bool
    public static let must_call_initial_tests = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "must call initial tests") ?? false) as! Bool
    public static let must_create_demo_ship_scene = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "must create demo ship scene") ?? false) as! Bool

    public static func printDuration(idx: Int, start_time: Date) {
        let duration = Date().timeIntervalSince(start_time)
        if duration > 0.001 {
            print("duration:\(idx): \(duration)")
        }
    }
    
    public static func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: date) + "." + String(date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)).sub(2)
    }
    
    // Basic debugging
    // Can be declared these ways:
    // static func here() -> () {
    // static func here() -> Void {
    // static func here() {
    public static func here() {
        if !must_log { return }
        print("here");
    }

    // Basic debugging
    // ex.: here("here")
    //      here("here", self)
    public static func here(_ s: String, _ o: Any? = nil) {
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

    public static func perror(_ str : String = "error") {
        print("\(str): \(String(cString: strerror(errno))) (\(errno))")
    }

    // Placeholder for tests
    public static func test(masterViewController: MasterViewController) {
//        c_test()
//        net_test()
//        let session = LocalHttpClient(url: "https://www.fenyo.net/bigfile")
        
//        let nb = NetworkBrowser(network: IPv4Address("10.69.184.0"), netmask: IPv4Address("255.255.255.0"), device_manager: masterViewController)
//        nb!.browse()
        
//        print("infos sur le device:", UIDevice.current.localizedModel, UIDevice.current.name, UIDevice.current.systemName, UIDevice.current.systemVersion, UIDevice.current.userInterfaceIdiom)

        print("TESTS INITIAUX")
        
        // RFC 3513 section 4 : IPv6 address space
        // link-local : FE80::/10
        // site-local : FEC0::/10
        // multicast  : FF::/8
        // le 2ième octet de poids fort contient le scope multicast dans ses 4 bits de poids faible (scope qui n'a rien à voir avec le scope de l'adresse IPv6)
        // les 3ièmes et 4ièmes octets de poids fort sont utilisés pour stocker le scope dans certaines adresses IPv6, quand le scope n'est pas global, c'est à dire pour les adresses qui ne sont pas global unicast
        // avec getNameInfo(), s'il y a un scope d'adresse IPv6, ce scope doit être l'index de l'interface réseau
        // les seules plages soumises à scope d'adresse IPv6 à l'intérieur de l'adresse sont :
        // FE80::/10 : c'est le scope d'adresse IPv6 link-local
        // FF01::/16 : c'est le scope multicast 1 : interface-local scope
        // FF02::/16 : c'est le scope multicast 2 : link-local scope
        // c'est le noyau FreeBSD qui utilise ce moyen de stockage du scope

        //        let x1 = IPv6Address("fe81:ab00::1")
        //        let x1 = IPv6Address("fe81:0002::1") // getNameInfo() : fe81::1%pdp_ip1
        //        let x1 = IPv6Address("ff02:0002::1") // getNameInfo() : ff02::1%pdp_ip1

        /*
        let x1 = IPv6Address("FEB0:0003::1") // getNameInfo() : ff02::1%pdp_ip1
        print(x1!.getRawBytes())
        print(x1!.scope)
        print(x1!.toSockAddress()!._getNameInfo(NI_NUMERICHOST)!)
        print("FIN DES TESTS INITIAUX")
        exit(0)
         */

        /*
        let x1 = IPv6Address("FE80:0003::1")
        print(x1!.getRawBytes())
        print(x1!.toSockAddress()!._getNameInfo(NI_NUMERICHOST)!)

         //        let addr = IPv4Address("82.64.215.180")
         //        addr?.toSockAddress()?.resolveHostName()

//        exit(0)
*/

        print("FIN DES TESTS INITIAUX")
    }

    // Espace insécable
    public static func insec() -> String {
        let arr: [UInt8] = [ 0xC2, 0xA0 ]
        return NSString(bytes: arr, length: arr.count, encoding: String.Encoding.utf8.rawValue)! as String
    }

    // Split a view controller with two columns of same width
    public static func splitViewControllerSameWidth(_ svc: UISplitViewController) {
        svc.preferredDisplayMode = .oneBesideSecondary
        svc.minimumPrimaryColumnWidth = 0
        svc.maximumPrimaryColumnWidth = CGFloat.greatestFiniteMagnitude
        svc.preferredPrimaryColumnWidthFraction = 0.5
    }

    // créer un alternate() indexé sur une chaîne de caractères
    private static func alternate() -> Bool {
        alternate_value = !alternate_value
        return alternate_value
    }

    public static func createScene(_ view: UIView) {
        if (GenericTools.ts.getElements().count == 0) {
            let date = Date() // test_date
            GenericTools.ts.add(TimeSeriesElement(date: date, value: 10.0))
            GenericTools.ts.add(TimeSeriesElement(date: date.addingTimeInterval(TimeInterval(-5.0)), value: 40.0))
            GenericTools.ts.add(TimeSeriesElement(date: date.addingTimeInterval(TimeInterval(-10.0)), value: 30.0))
            GenericTools.ts.add(TimeSeriesElement(date: date.addingTimeInterval(TimeInterval(-20.0)), value: 50.0))
            GenericTools.ts.add(TimeSeriesElement(date: date.addingTimeInterval(TimeInterval(-45.0)), value: 15.0))
            GenericTools.ts.add(TimeSeriesElement(date: date.addingTimeInterval(TimeInterval(-55.0)), value: 12.0))
        }
        if !alternate() { createSpriteScene(view as! SKView) }
        else { create3DChartScene(view as! SCNView) }
    }

    // Insert the demo cube scene into a view
    public static func createCubeSceneTest(_ view: SCNView) {
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
        view.backgroundColor = .black

//        // add a tap gesture recognizer
//        let manage_tap = ManageTapCube(view)
//        // create a strong ref to the target
//        tap_cube_manager.append(manage_tap)
//        let tapGesture = UITapGestureRecognizer(target: manage_tap, action: #selector(ManageTapCube.handleTap(_:)))
//        view.addGestureRecognizer(tapGesture)
    }

    public static func createSpriteScene(_ view: SKView) {
        // Create a scene
        let scene = SKScene(size: CGSize(width: view.frame.size.width / 2, height: view.frame.size.height))
        scene.backgroundColor = .white
        view.presentScene(scene)

        chart_node = SKChartNode(ts: ts, full_size: CGSize(width: 410, height: 300), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 80, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false)
        scene.addChild(chart_node!)
        chart_node!.position = CGPoint(x: 50, y: 100)
        chart_node!.registerGestureRecognizers(view: view/*, delta: 0*/)

        // Display debug informations
        view.showsFPS = true
        view.showsQuadCount = true
    }
    
    // Insert a 3D scene containing a 2D Chart into a view
    public static func create3DChartScene(_ view: SCNView) {
        // create a new scene
        let scene = SCNScene()

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        
        // set the scene to the view
        view.scene = scene
        
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        view.showsStatistics = true

        // configure the view
        view.backgroundColor = .black
     
        // add a tap gesture recognizer
        let manage_tap = ManageTapCube(view)
        // create a strong ref to the target
        tap_cube_manager.append(manage_tap)
        let tapGesture = UITapGestureRecognizer(target: manage_tap, action: #selector(ManageTapCube.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        plane_node = SCNChartNode(ts: ts, density: 450, full_size: CGSize(width: 800, height: 600), grid_size: CGSize(width: 800 / 5, height: 800 / 5), subgrid_size: CGSize(width: 20, height: 20), line_width: 5, left_width: 250, bottom_height: 150, vertical_unit: "Kbit/s", grid_vertical_cost: 20, date: Date(), grid_time_interval: 10, background: .gray, max_horizontal_font_size: 38, max_vertical_font_size: 45, vertical_auto_layout: true, debug: false)
        scene.rootNode.addChildNode(plane_node!)
    }
    
    // Insert the demo ship scene into a view
    public static func createDemoShipScene(_ view: SCNView) {
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
        view.backgroundColor = .black
        
        // add a tap gesture recognizer
        let manageTap = ManageTapDemoShip(view)
        // create a strong ref to the target
        tap_demo_ship_manager.append(manageTap)
        let tapGesture = UITapGestureRecognizer(target: manageTap, action: #selector(manageTap.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
}

// manage a tap on a demo ship scene view
private class ManageTapDemoShip {
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
private class ManageTapCube {
    let scnView: SCNView

    init(_ v: SCNView) {
        self.scnView = v
    }

    var step: Int = 0

    // Callback used by createDemoShipScene()
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        return ;
 
//        GenericTools.here("Tap")
//
//        // SCNTransaction.begin()
//
//        step += 1
//
//        //        if (step == 1) {
////            print("avant remove actions")
////            GenericTools.chart_node!.grid_node!.removeAllActions()
////        }
////        if (step == 2) {
////            GenericTools.chart_node!.testDebug()
////        }
//        
////        if (step == 3) {
//        SCNTransaction.begin()
//        // XXX
//        // si j'ajoute plein de points très vite : crash
//        if( step < 2) { GenericTools.ts.add(TimeSeriesElement(date: Date(), value: 10.0 * Float(step))) }
//
//        if (step == 2) { GenericTools.ts.add(TimeSeriesElement(date: Date(), value: 1000.0)) }
//        if (step == 3) { GenericTools.ts.add(TimeSeriesElement(date: Date(), value: 200000.0)) }
//        if (step == 4) { GenericTools.ts.add(TimeSeriesElement(date: Date(), value: 3000000.0)) }
//        if (step == 5) { GenericTools.ts.add(TimeSeriesElement(date: Date(), value: 850000000.0)) }
//
//        SCNTransaction.commit()
//
//
//        SCNTransaction.begin()
////        GenericTools.chart_node!.updateGridVerticalCost(40.0)
//        SCNTransaction.commit()
//
//
//        SCNTransaction.begin()
////        GenericTools.plane_node!.chart_node!.updateGridVerticalCost(40.0)
//        SCNTransaction.commit()
//
////        GenericTools.chart_node!.grid_node!.removeAllActions()
//
////        }
//        // SCNTransaction.commit()
//
//            // highlight it
////            SCNTransaction.begin()
////            scnView.debugOptions.insert(SCNDebugOptions.showWireframe)
////            scnView.debugOptions.insert(SCNDebugOptions.renderAsWireframe)
////            SCNTransaction.commit()
    }
}

protocol AutoTrace {
}

extension AutoTrace {
    
}
