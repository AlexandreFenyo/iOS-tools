
// DEBUG FLICKER

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
    

    // - scene
    //   - camera
    //   - chart_node
    //     - shape_node

    static func createSpriteScene(_ view: SKView) {
        // Create a scene
        let scene = SKScene(size: view.frame.size)

        // XXXXXXXXXXX
        // Configure properties for the scene
        scene.backgroundColor = SKColor.white
        view.presentScene(scene)

        // Add a camera (optional)
        let cam = SKCameraNode()
        scene.camera = cam
        scene.addChild(cam)
        cam.position = CGPoint(x: 600, y: 600)
        // pas de flicker
        //        let zoomInAction = SKAction.scale(to: 0.1, duration: 10)
        // flicker
        //        let zoomInAction = SKAction.scale(to: 2.0, duration: 10)
        //        cam.run(zoomInAction)
        // pas de flicker
        //        cam.setScale(0.5)
        // flicker
        cam.setScale(2.0)

        // Add a chart
        let chart_node = ChartNode(size: CGSize(width: view.frame.width, height: view.frame.width), grid_size: CGSize(width: 20, height: 40))

        // Configure properties for chart_node
        // XXXXXXXXXXX
        chart_node.position = CGPoint(x: 0, y: 0)

        // Make chart_node a child of scene
        scene.addChild(chart_node)

        // Display debug informations
        view.showsFPS = true
        view.showsQuadCount = true
    }

}
