
// DEBUG FLICKER / FLASHING / BLINKING
// Extrude opaque images by 1 pixel - this prevents flashing images when rendering ???

import Foundation
import UIKit
import SpriteKit

final class GenericTools {
    // extract configuration parameters
    static let must_log = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "log") ?? false) as! Bool
    static let must_call_initial_tests = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "must call initial tests") ?? false) as! Bool
    static let must_create_demo_ship_scene = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "must create demo ship scene") ?? false) as! Bool

    static func here() {
        if !must_log { return }
        print("here");
    }

    static func here(_ s: String, _ o: Any? = nil) {
        if !must_log { return }
        if o == nil {
            print("here:", s);
        } else {
            print("here: ", o!, ":", s, separator: String() /* alt: separator: "" */)
        }
    }

    // - view
    //   - scene: backgroundColor=clear, zPosition=1, blendMode=replace
    //     - camera
    //     - chart_node: color=clear, zPosition=5, blendMode=replace
    //       - shape_node: zPosition=10, strokeColor=red

    static func createSpriteScene(_ view: SKView) {
        // Create a scene
        let scene = SKScene(size: view.frame.size)

        // XXXXXXXXXXX
        // Configure properties for the scene
        scene.backgroundColor = SKColor.clear
        scene.blendMode = .replace
        // scene.scaleMode semble pas concerné
        // scene.alpha pas concerné
        // scene.attributeValues
        // scene.blendMode
        // scene.filter ???
        // scene.setValue(...)
        // scene.shader ???
        scene.zPosition = 1.0
//        scene.shouldRasterize = true
        scene.shouldCenterFilter = true
        scene.shouldEnableEffects = true

        // Add scene to view
        view.presentScene(scene)

        // Add a camera (optional)
        let cam = SKCameraNode()
        scene.camera = cam
        scene.addChild(cam)
        cam.position = CGPoint(x: 600, y: 600)
        // flicker
        cam.setScale(2.0)

        // Add a chart
        let chart_node = ChartNode(size: CGSize(width: view.frame.width, height: view.frame.width), grid_size: CGSize(width: 20, height: 40))

        // XXXXXXXXXXX
        // Configure properties for chart_node
        chart_node.position = CGPoint(x: 0, y: 0)

        // Make chart_node a child of scene
        scene.addChild(chart_node)

        // Display debug informations
        view.showsFPS = true
        view.showsQuadCount = true
    }

}
