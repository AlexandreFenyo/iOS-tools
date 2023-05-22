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
    
    private weak var renderer_delegate: SCNSceneRendererDelegate?
    
    init() {
        scene = SCNScene(named: "Interman 3D Scene.scn")!
        Interman3DModel.shared.scene = scene
        camera = scene.rootNode.childNode(withName: "camera", recursively: true)!
        camera.camera!.usesOrthographicProjection = true
    }

    public func getTappedHost(_ point: CGPoint) -> B3DHost? {
        return render_delegate.getRenderer().hitTest(point, options: [.ignoreHiddenNodes : true, .searchMode : SCNHitTestSearchMode.all.rawValue]).compactMap { B3DHost.getFromNode($0.node) }.first
    }
    
    public func getCameraAngle() -> Float {
        return camera.eulerAngles.y
    }

    // Set angle absolute value
    public func rotateCamera(_ angle: Float) {
        var new_angle = angle.truncatingRemainder(dividingBy: 2 * .pi)
        if new_angle < 0 { new_angle += 2 * .pi }
        camera.eulerAngles.y = new_angle
    }

    public func getCameraScaleFactor() -> Float {
        return camera.simdScale.x
    }

    // Set scale factor absolute value
    public func scaleCamera(_ factor: Float) {
        camera.simdScale = SIMD3<Float>(factor, factor, factor)
    }

    public func resetCamera() {
        var duration = camera.eulerAngles.y
        if duration > .pi { duration = 2 * .pi - duration }
        if duration != 0 {
            camera.runAction(SCNAction.rotateTo(x: -.pi / 2, y: 0, z: 0, duration: Double(duration) / .pi, usesShortestUnitArc: true))
        }

        camera.runAction(SCNAction.scale(to: 2, duration: 0.5))
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
