//
//  IntermanSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/03/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SceneKit

class RenderDelegate: NSObject, SCNSceneRendererDelegate {
    private var renderer: SCNSceneRenderer!
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        self.renderer = renderer
    }

    public func getRenderer() -> SCNSceneRenderer {
        return renderer
    }
}

struct Interman3DSwiftUIView: View {
    public weak var master_view_controller: MasterViewController?
    @ObservedObject var model = Interman3DModel.shared
    private let camera: SCNNode
    let scene: SCNScene
    private var render_delegate = RenderDelegate()
    
    init() {
        scene = SCNScene(named: "Interman 3D Scene.scn")!
        Interman3DModel.shared.scene = scene
        camera = scene.rootNode.childNode(withName: "camera", recursively: true)!
        camera.camera!.usesOrthographicProjection = true
        camera.camera!.automaticallyAdjustsZRange = true
        camera.pivot = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
        camera.position = SCNVector3(0, 5, 0)
        camera.scale = SCNVector3(2, 2, 2)
    }

    func getTappedHost(_ point: CGPoint) -> B3DHost? {
        return render_delegate.getRenderer().hitTest(point, options: [.ignoreHiddenNodes : true, .searchMode : SCNHitTestSearchMode.all.rawValue]).compactMap { B3DHost.getFromNode($0.node) }.first
    }
    
    func getCameraAngle() -> Float {
        return Interman3DModel.normalizeAngle(camera.eulerAngles.y)
    }

    // Set angle absolute value
    func rotateCamera(_ angle: Float) {
//        print("-----------------")
        let angle = Interman3DModel.normalizeAngle(angle)
        print("rotate camera to: \(angle) = \(angle * 360 / (.pi * 2)) degrés")
//        print("rotate to angle: \(angle) = \(angle * 360 / (.pi * 2)) degrés")
//        print("rotateCamera(): camera.rotation=\(camera.rotation)")
//        print("rotateCamera(): camera.orientation=\(camera.orientation)")

        // Similar to: camera.eulerAngles.y = angle
        camera.runAction(SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0))
    }

    // Get scale factor
    func getCameraScaleFactor() -> Float {
        return camera.simdScale.x
    }

    // Set scale factor
    func scaleCamera(_ factor: Float) {
        camera.simdScale = SIMD3<Float>(factor, factor, factor)
    }

    func resetCamera() {
        var duration = Interman3DModel.normalizeAngle(camera.eulerAngles.y)
        if duration > .pi { duration = 2 * .pi - duration }
        camera.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: Double(duration) / .pi, usesShortestUnitArc: true))
        camera.runAction(SCNAction.scale(to: 2, duration: 0.5))
    }

    func testQuat() {
    }
    
    func setSelectedHost(_ host: Node) {
        guard let node = model.getB3DHost(host) else { return }
        
        let angle = node.getAngle()
        print("setSelectedHost: to angle: \(angle) = \(angle * 360 / (.pi * 2)) degrés")
        var duration = angle
        if duration > .pi { duration = 2 * .pi - duration }
        camera.runAction(SCNAction.rotateTo(x: 0, y: -CGFloat(angle), z: 0, duration: Double(duration) / .pi, usesShortestUnitArc: true))
    }
    
    var body: some View {
        ZStack {
            SceneView(
                scene: scene,
                options: [
                // If allowed, the user takes control of the camera, therefore not any pan or pinch gestures will be fired
                // .allowsCameraControl
                ],
                delegate: render_delegate
            )
            .edgesIgnoringSafeArea(.all)
          VStack {
            Spacer()

            HStack {
              HStack {
                  Button {
                      model.addComponent()
                  } label: {
                      Text("create")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }
              }

              Spacer()
              Text("salut").foregroundColor(.white)
              Spacer()
                Button {
                    model.testComponent()
                    testQuat()
                } label: {
                    Text("update")
                    Image(systemName: "xmark.circle.fill").imageScale(.large)
                }
            }
            .padding(8)
            .cornerRadius(14)
            .padding(12)
          }
        }
    }
}
