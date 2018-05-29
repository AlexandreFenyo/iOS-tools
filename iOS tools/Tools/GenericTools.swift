//
//  GenericTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

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

final class GenericTools {
    public static var plane_node : SCNChartNode?
    public static var chart_node : SKChartNode?

    private static var alternate_value = true

    public static let ts = TimeSeries()
    
    // extract configuration parameters
    public static let must_log = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "log") ?? false) as! Bool

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

    // Placeholder for tests
    public static func test() {
    }

    // Espace insécable
    public static func insec() -> String {
        let arr: [UInt8] = [ 0xC2, 0xA0 ]
        return NSString(bytes: arr, length: arr.count, encoding: String.Encoding.utf8.rawValue)! as String
    }

    // Split a view controller with two columns of same width
    public static func splitViewControllerSameWidth(_ svc: UISplitViewController) {
        svc.preferredDisplayMode = .allVisible
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
        if !alternate() { createSpriteScene(view as! SKView) }
        else { create3DChartScene(view as! SCNView) }
    }

    public static func createSpriteScene(_ view: SKView) {
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

        // configure the view
        view.backgroundColor = .black
     
        plane_node = SCNChartNode(ts: ts, density: 450, full_size: CGSize(width: 800, height: 600), grid_size: CGSize(width: 800 / 5, height: 800 / 5), subgrid_size: CGSize(width: 20, height: 20), line_width: 5, left_width: 250, bottom_height: 150, vertical_unit: "Kbit/s", grid_vertical_cost: 20, date: Date(), grid_time_interval: 10, background: .gray, max_horizontal_font_size: 38, max_vertical_font_size: 45, vertical_auto_layout: true, debug: false)
        scene.rootNode.addChildNode(plane_node!)
        plane_node!.registerGestureRecognizers(view: view)
    }
    
    // Insert the demo ship scene into a view
    public static func createDemoShipScene(_ view: SCNView) { }
}

