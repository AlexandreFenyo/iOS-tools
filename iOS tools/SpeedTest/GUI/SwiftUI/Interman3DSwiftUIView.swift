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
//    private var camera_angle: Float = 0
    let scene: SCNScene

    private var render_delegate = RenderDelegate()
    
    private weak var renderer_delegate: SCNSceneRendererDelegate?
    
    init() {
        scene = SCNScene(named: "Interman 3D Scene.scn")!
        Interman3DModel.shared.scene = scene
        camera = scene.rootNode.childNode(withName: "camera", recursively: true)!
        camera.camera!.usesOrthographicProjection = true
    }

    func getTappedHost(_ point: CGPoint) -> B3DHost? {
        return render_delegate.getRenderer().hitTest(point, options: [.ignoreHiddenNodes : true, .searchMode : SCNHitTestSearchMode.all.rawValue]).compactMap { B3DHost.getFromNode($0.node) }.first
    }
    
    func getCameraAngle() -> Float {
        // ICI
        return Interman3DModel.normalizeAngle(camera.eulerAngles.y)
    }

    // Set angle absolute value
    func rotateCamera(_ angle: Float) {

        print("rotateCamera(): camera.rotation=\(camera.rotation)")
        print("rotateCamera(): camera.orientation=\(camera.orientation)")
//        print(camera.position) // vecteur (0, 5, 0)
//        print(camera.pivot) // matrice identité
        
        
        // ICI
        camera.eulerAngles.y = Interman3DModel.normalizeAngle(angle)
//        camera.runAction(SCNAction.rotateTo(x: -.pi / 2, y: CGFloat(Interman3DModel.normalizeAngle(angle)), z: 0, duration: 0))
//        camera_angle = angle
    }

    func getCameraScaleFactor() -> Float {
        return camera.simdScale.x
    }

    // Set scale factor absolute value
    func scaleCamera(_ factor: Float) {
        camera.simdScale = SIMD3<Float>(factor, factor, factor)
    }

    func resetCamera() {
        var duration = Interman3DModel.normalizeAngle(camera.eulerAngles.y)
        if duration > .pi { duration = 2 * .pi - duration }
        if duration != 0 {
            // ICI
            camera.runAction(SCNAction.rotateTo(x: -.pi / 2, y: 0, z: 0, duration: Double(duration) / .pi, usesShortestUnitArc: true))
        }

        camera.runAction(SCNAction.scale(to: 2, duration: 0.5))
    }

    func testQuat() {
        print("---------- testQuat -------")
        
//        print("testQuat(): camera.rotation=\(camera.rotation)")
//        print("testQuat(): camera.orientation=\(camera.orientation)")
        
        // /Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk/usr/include/simd/quaternion.h

        // ICI on teste différentes valeurs
//        camera.rotation = SCNQuaternion(simd_quatf(angle: 1.5707964, axis: SIMD3(-1, 0, 0)).vector)
//        camera.orientation = SCNQuaternion(simd_quatf(angle: 1.5707964, axis: SIMD3(-1, 0, 0)).vector)
//        camera.orientation = simd_quatf(angle: 1.5707964, axis: SIMD3(-1, 0, 0))
        //let foo: Bool = simd_quatf(angle: 1.5707964, axis: SIMD3(-1, 0, 0))
//        SCNQuaternion(simd_quatf)

//        let foo : Int =        camera.transform
//        camera.rotation = SCNVector4(-1, 0, 0, 0.1)
//        let transf = SCNMatrix4MakeTranslation(0, 5, 0)
//       camera.transform = SCNMatrix4Identity
//        camera.pivot = SCNMatrix4MakeTranslation(0, -0.4, 0)
//      camera.transform = SCNMatrix4MakeRotation(-90/(2 * Float(M_PI)), 1, 0, 0)
//        camera.transform = SCNMatrix4MakeRotation(0/(2 * Float(M_PI)), 1, 0, 0)

//        let foo = camera.transform // = SCNMatrix4MakeTranslation(0, 0.4, 0) //* SCNMatrix4MakeRotation(0.1, 0, 1, 0)
//        print(camera.transform)
//        print(camera.position)
//        camera.transform = SCNMatrix4Identity
  //      camera.transform = SCNMatrix4MakeRotation(0, 0, 1, 90/(2 * Float(M_PI)))
//        camera.rotation = SCNVector4(-1, 0, 0, 90/(2 * M_PI))

        

        camera.position = SCNVector3(0, 1, 0)
        camera.eulerAngles.x = -(Float.pi / 4)
        camera.scale = SCNVector3(2, 2, 2)
        
        
//        print("testQuat(): camera.rotation=\(camera.rotation)")
//        print("testQuat(): camera.orientation=\(camera.orientation)")

    }
    
    func setSelectedHost(_ host: Node) {
        guard let node = model.getB3DHost(host) else { return }
        
        let angle = node.getAngle()


        var duration = angle
        if duration > .pi { duration = 2 * .pi - duration }
        if duration != 0 {

            /*        self.angle = Interman3DModel.normalizeAngle(angle)
             
             // Stop any current movement
             simdPivot = presentation.simdPivot
             removeAnimation(forKey: "circle")

             // Animate to new position
             let rot = simd_float4x4(simd_quatf(angle: angle, axis: SIMD3(0, 1, 0)))
             var transl = matrix_identity_float4x4
             transl[3, 0] = -1
             let animation = CABasicAnimation(keyPath: "pivot")
             animation.toValue = SCNMatrix4(transl * rot)
             animation.duration = 1
             animation.fillMode = .forwards
             animation.isRemovedOnCompletion = false
             addAnimation(animation, forKey: "circle")
*/

//            camera.eulerAngles.y = Interman3DModel.normalizeAngle(-angle)


            // ICI
            //            simdPivot = presentation.simdPivot
                        camera.removeAnimation(forKey: "circle")
                      let animation = CABasicAnimation(keyPath: "orientation")

            print(camera.orientation)
            
            animation.fromValue = camera.orientation
animation.toValue = SCNQuaternion(simd_quatf(angle: 0.7, axis: SIMD3(0, 1, 0)).vector)
//animation.toValue = SCNVector4(x: 0, y: 1, z: 0, w: 1.5707964)

            
            // camera.rotation // SCNMatrix4MakeRotation(-1, 0, 0, 1.5)
                        animation.duration = 10
                    animation.fillMode = .forwards
                  animation.isRemovedOnCompletion = false
                        camera.addAnimation(animation, forKey: "xcircle")
                        
            //            print("XXXXX: cam orientation: \(camera.orientation)")


            /*
//            simdPivot = presentation.simdPivot
            camera.removeAnimation(forKey: "circle")
          let animation = CABasicAnimation(keyPath: "orientation")
            animation.fromValue = camera.orientation
            //animation.toValue = SCNQuaternion(simd_quatf(angle: 0.7, axis: SIMD3(-0.7, 0, 0)).vector)
            animation.toValue = SCNQuaternion(x: -0.70710677, y: 0.0, z: 0.0, w: 0.70710677)
            animation.duration = 0.1
        animation.fillMode = .forwards
      animation.isRemovedOnCompletion = false
            camera.addAnimation(animation, forKey: "circle")
            
//            print("XXXXX: cam orientation: \(camera.orientation)")
*/
            
            
            
            //            camera.runAction(SCNAction.rotateTo(x: -.pi / 2, y: -CGFloat(angle), z: 0, duration: 4 * Double(duration) / .pi, usesShortestUnitArc: true))
            // Since SCNAction.rotateTo() does not always use euler angles like we would expect (sometimes it adds PI to x and z, this leads to have y being counted counterwise), and that we use eulerAngle directly in other functions of this file, we need to handle the following two cases to stay consistent.

            /*
            if angle > .pi / 2 && angle < 3 * .pi / 2 {
                camera.runAction(SCNAction.rotateTo(x: .pi / 2, y: -CGFloat(angle), z: .pi, duration: 4 * Double(duration) / .pi, usesShortestUnitArc: true))
            } else {
                camera.runAction(SCNAction.rotateTo(x: -.pi / 2, y: .pi + CGFloat(angle), z: 0, duration: 4 * Double(duration) / .pi, usesShortestUnitArc: true))
                }
             */
            
        }
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
