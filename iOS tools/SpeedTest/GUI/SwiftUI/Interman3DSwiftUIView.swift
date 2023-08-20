//
//  IntermanSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/03/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SceneKit

private enum CameraMode : String {
    case topManual, topStepper, sideManual, sideStepper, topHostManual, topHostStepper, freeFlight
}

private class CameraModel: ObservableObject {
    static let shared = CameraModel()

    @Published private(set) var camera_mode: CameraMode = CameraMode.topManual

    func setCameraMode(_ mode: CameraMode)  {
        camera_mode = mode
    }
    
    func nextCameraMode() {
        /*
        if camera_mode == .topManual {
            camera_mode = .sideManual
        } else {
            camera_mode = .topManual
        }
return*/
        
        switch camera_mode {
        case .topManual:
            camera_mode = .freeFlight
//            camera_mode = .topStepper
        case .topStepper:
            camera_mode = .sideManual
        case .sideManual:
            camera_mode = .sideStepper
        case .sideStepper:
            camera_mode = .topHostManual
        case .topHostManual:
            camera_mode = .topHostStepper
        case .topHostStepper:
            camera_mode = .topManual
//            camera_mode = .freeFlight
        case .freeFlight:
            camera_mode = .topManual
        }
    }
    
    func getCameraMode() -> CameraMode {
        return camera_mode
    }
}

private class RenderDelegate: NSObject, SCNSceneRendererDelegate {
    private var renderer: SCNSceneRenderer!
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        self.renderer = renderer
    }

    func getRenderer() -> SCNSceneRenderer {
        return renderer
    }
}

struct Interman3DSwiftUIView: View {
    weak var master_view_controller: MasterViewController?

    @State private var free_flight_active: Bool = false
    
    @State private var timer_camera: Timer?
    @State private var timer_text: Timer?

    @ObservedObject private var interman3d_model = Interman3DModel.shared
    @ObservedObject private var model = TracesViewModel.shared

    @ObservedObject private var camera_model = CameraModel.shared
    private let camera: SCNNode
    private let scene: SCNScene

    private var render_delegate = RenderDelegate()
    


    
    
    
    init() {
        scene = Interman3DModel.shared.scene
        camera = Interman3DModel.shared.scene.rootNode.childNode(withName: "camera", recursively: true)!
        
        
        
        camera.camera!.usesOrthographicProjection = true
        camera.camera!.automaticallyAdjustsZRange = true

        // Debug: axes
        scene.rootNode.addChildNode(ComponentTemplates.createAxes(0.2))

        print(camera.presentation.pivot)
        print(camera.pivot)
        print(camera.presentation.transform)
        print(camera.transform)

        // Set camera initial position
        camera.scale = SCNVector3(2, 2, 2)
        camera.pivot = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
        camera.position = SCNVector3(0, 5, 0)

        print(camera.presentation.pivot)
        print(camera.pivot)
        print(camera.presentation.transform)
        print(camera.transform)

        // https://github.com/FlexMonkey/SkyCubeTextureDemo/blob/master/SkyCubeDemonstration/ViewController.swift
        /*
        scene.background.contents = MDLSkyCubeTexture(name: nil,
                                                      channelEncoding: MDLTextureChannelEncoding.uInt8,
                                                      textureDimensions: [Int32(160), Int32(160)],
                                                      turbidity: 0.75,
                                                      sunElevation: 7,
                                                      upperAtmosphereScattering: 0.15,
                                                      groundAlbedo: 0.85)
         */
        
//        let sky = scene.background.contents as! MDLSkyCubeTexture
//        sky.groundColor = .init(red: 1, green: 1, blue: 1, alpha: 1) // COLORS.leftpannel_bg.cgColor
    }

    func getTappedHost(_ point: CGPoint) -> B3DHost? {
        return render_delegate.getRenderer().hitTest(point, options: [.ignoreHiddenNodes : true, .searchMode : SCNHitTestSearchMode.all.rawValue]).compactMap { B3DHost.getFromNode($0.node) }.first
    }
    
    // ////////////////////////////////
    // Manage camera
    
    func getCameraAngle() -> Float {
        // Note that Euler angles (0, u, 0) and Euler angles (π, π-u, π) correspond to the same orientation
        return Interman3DModel.normalizeAngle(camera.parent!.presentation.eulerAngles.x == 0 ? camera.parent!.presentation.eulerAngles.y : (-camera.parent!.presentation.eulerAngles.y + .pi))
    }

    // Set camera absolute orientation value
    func rotateCamera(_ angle: Float, smooth: Bool, duration _duration: Float? = nil, usesShortestUnitArc: Bool = false) {
//        if free_flight { return }

        if smooth {
            var duration: Float
            if let _duration { duration = _duration }
            else {
                duration = Interman3DModel.normalizeAngle(getCameraAngle() - angle)
                if duration > .pi { duration = 2 * .pi - duration }
                duration = duration / .pi
                // Duration is between 0 (no movement) and 1 sec (half turn)
            }

            // We do not use SCNAction.rotateTo since it can have side effects, because it can update not only the euler.y angle, but other parameters too
            let animation = CABasicAnimation(keyPath: "euler.y")
            animation.fromValue = CGFloat(getCameraAngle())
            // Do not set toValue to Interman3DModel.normalizeAngle(angle) but to 2 * .pi + CGFloat(angle), since it would make a full turn when coming back to the node at 0 degrees
            animation.toValue = 2 * .pi + CGFloat(angle)
            animation.duration = CFTimeInterval(duration)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            camera.parent!.addAnimation(animation, forKey: "rotation")
        } else {
            camera.parent!.removeAnimation(forKey: "rotation")
            camera.parent!.eulerAngles.y = angle
        }
    }

    private func resetCameraTimer() {
        updateCameraIfNeeded()
        timer_camera?.invalidate()
        timer_camera = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            updateCameraIfNeeded()
        }
    }
    
    private func nextCameraMode() {
        camera_model.nextCameraMode()
        setCameraMode(camera_model.camera_mode)
    }

    public func testCamera() {
        var foo = camera.presentation.pivot
        print(foo)
        foo = camera.pivot
        print(foo)
        var bar = camera.presentation.transform
        print(bar)
        bar = camera.transform
        print(bar)
    }
    
    private func setCameraMode(_ mode: CameraMode) {
        camera_model.setCameraMode(mode)
        
        let sphere = scene.rootNode.childNode(withName: "sphere", recursively: true)!

        switch camera_model.camera_mode {
        case .topManual:
            free_flight_active = false

            /*
            camera.removeAllAnimations()
            camera.pivot = SCNMatrix4Identity
            camera.transform = SCNMatrix4Identity
            camera.scale = SCNVector3(x: 1.0, y: 1.0, z: 1.0)
            camera.parent!.pivot = SCNMatrix4Identity
            camera.parent!.transform = SCNMatrix4Identity
            camera.parent!.scale = SCNVector3(x: 1.0, y: 1.0, z: 1.0)
            camera.pivot = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
            camera.position = SCNVector3(0, 5, 0)
            camera.scale = SCNVector3(2, 2, 2)
*/

            /* les pbs d'animation pas smooth quand on revient ici après un cycle, étudier ceci :
             camera.removeAllAnimations()
*/

//            camera.removeAllAnimations()

            let foo = camera.presentation.pivot
            let bar = camera.presentation.transform
            print(foo)
            print(bar)
  //          camera.removeAllAnimations()

            camera.parent!.runAction(SCNAction.scale(to: 2, duration: 0.5))

            var animation = CABasicAnimation(keyPath: "pivot")
            animation.fromValue = foo
            animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
            animation.duration = 1
//            animation.fillMode = .forwards
//            animation.isRemovedOnCompletion = false
            camera.addAnimation(animation, forKey: "campivot")
            camera.pivot = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)

            animation = CABasicAnimation(keyPath: "transform")
//            animation.fromValue = bar
            animation.toValue = SCNMatrix4MakeTranslation(0, 5, 0)
            animation.duration = 1
//            animation.fillMode = .forwards
//            animation.isRemovedOnCompletion = false
            camera.addAnimation(animation, forKey: "camtransform")
            camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
            
        case .topStepper:
            resetCameraTimer()

        case .sideManual:
            free_flight_active = false

            camera.parent!.runAction(SCNAction.scale(to: 1, duration: 0.5))

            var animation = CABasicAnimation(keyPath: "pivot")
            animation.toValue = SCNMatrix4Identity
            animation.duration = 1
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            camera.addAnimation(animation, forKey: "campivot")

            animation = CABasicAnimation(keyPath: "transform")
            animation.toValue = SCNMatrix4MakeTranslation(0, 1, 2)
            animation.duration = 1
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            camera.addAnimation(animation, forKey: "camtransform")

            let lookAtConstraint = SCNLookAtConstraint(target: sphere)
            lookAtConstraint.isGimbalLockEnabled = false
            camera.constraints = [lookAtConstraint]
            
        case .sideStepper:
            resetCameraTimer()

        case .topHostManual:
            free_flight_active = false

//            camera.removeAllAnimations()
            
            // Si on se contente de supprimer la contrainte sans conserver le pivot, alors cela implique que ce n'est plus smooth pour aller vers ce mode, mais laisser la contrainte crée une petite rotation dans le sens trigo inverse qu'on peut faire disparaître en élevant la caméra jusqu'à 70 (plus de 80 implique que le logo Apple au dos d'un iPad, en mode auto, se met à "vibrer" quand il tourne)
            let current_pivot = camera.presentation.pivot
            camera.constraints?.removeAll()
            camera.pivot = current_pivot
            
            camera.parent!.runAction(SCNAction.scale(to: 2, duration: 0.5))

            var animation = CABasicAnimation(keyPath: "pivot")
            animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
            animation.duration = 1
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            camera.addAnimation(animation, forKey: "campivot")

            animation = CABasicAnimation(keyPath: "transform")
            animation.toValue = SCNMatrix4MakeTranslation(0.5, 5, 0)
            animation.duration = 1
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            camera.addAnimation(animation, forKey: "camtransform")
            
        case .topHostStepper:
            resetCameraTimer()

camera.removeAllAnimations()

            
        case .freeFlight:
//            free_flight = true
            free_flight_active = true
//            scene_view_options = [.allowsCameraControl]

            camera.pivot = SCNMatrix4Identity
            camera.transform = SCNMatrix4Identity
            camera.scale = SCNVector3(x: 1.0, y: 1.0, z: 1.0)
            camera.parent!.pivot = SCNMatrix4Identity
            camera.parent!.transform = SCNMatrix4Identity
            camera.parent!.scale = SCNVector3(x: 1.0, y: 1.0, z: 1.0)

            /*
            camera.pivot = initval_camera_pivot
            camera.transform = initval_camera_transform
            camera.scale = initval_camera_scale
            camera.parent!.pivot = initval_camera_parent_pivot
            camera.parent!.transform = initval_camera_parent_transform
            camera.parent!.scale = initval_camera_parent_scale
*/
            
            camera.transform = SCNMatrix4MakeRotation(-.pi / 2, 1, 0, 0)
            camera.position = SCNVector3(0, 5, 0)
            camera.scale = SCNVector3(2, 2, 2)
        }
    }

    private func updateTextIfNeeded() {
        interman3d_model.scheduledTextUpdate()
    }
    
    private func updateCameraIfNeeded() {
        if camera_model.getCameraMode() == .sideStepper || camera_model.getCameraMode() == .topStepper || camera_model.getCameraMode() == .topHostStepper {
            let host = interman3d_model.getLowestNodeAngle(getCameraAngle())
            rotateCamera(-host.getAngle(), smooth: true, duration: 1)
        }
    }
    
    // Get scale factor
    func getCameraScaleFactor() -> Float {
        return camera.parent!.simdScale.x
    }

    // Set scale factor
    func scaleCamera(_ factor: Float) {
        camera.parent!.simdScale = SIMD3<Float>(factor, factor, factor)
    }

    func resetCamera() {
        rotateCamera(0, smooth: true, duration: 1)
        camera.parent!.runAction(SCNAction.scale(to: 2, duration: 0.5))
    }

    // ////////////////////////////////

    func testQuat() {
    }
    
    func setSelectedHost(_ host: Node) {
        guard let node = interman3d_model.getB3DHost(host) else { return }
        let new_camera_angle = -node.getAngle()
        rotateCamera(new_camera_angle, smooth: true)
    }
    
    // .allowsCameraControl: if allowed, the user takes control of the camera, therefore not any pan or pinch gestures will be fired
//    @State var scene_view_options = free_flight ? [.allowsCameraControl] : SceneView.Options()

    // Needed by traces
    @Namespace var topID
    @Namespace var bottomID
    private struct ScrollViewOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = .zero
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value += nextValue()
        }
    }
    @State private var timer: Timer?

    var body: some View {

        ZStack {
            // 3D view
            
            // CONTINUER ICI : faire deux vues, une en free_flight, pas l'autre

            if free_flight_active == true {
                SceneView(
                    scene: scene,
                    options: [.allowsCameraControl],
                    delegate: render_delegate
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                SceneView(
                    scene: scene,
                    options: SceneView.Options(),
                    delegate: render_delegate
                )
                .edgesIgnoringSafeArea(.all)
            }

            // Traces
            GeometryReader { traceGeom in
                 ScrollViewReader { scrollViewProxy in
                     ZStack {
                         ScrollView {
                             ZStack {
                                 LazyVStack(alignment: .leading, spacing: 0) {
                                     Spacer().id(topID)
                                     ForEach(0 ..< model.traces.count - 1, id: \.self) { i in
                                         Text(model.traces[i]).font(.footnote)
                                             .lineLimit(nil)
                                             .foregroundColor(Color(COLORS.standard_background.darker().darker()))
                                     }
                                     Text(model.traces.last!)
                                         .font(.footnote)
                                         .id(bottomID)
                                         .lineLimit(nil)
                                         .foregroundColor(Color(COLORS.standard_background.darker().darker()))
                                 }.padding()
                                 GeometryReader { scrollViewContentGeom in
                                     Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: traceGeom.size.height - scrollViewContentGeom.size.height - scrollViewContentGeom.frame(in: .named("scroll")).minY)
                                 }
                             }
                         }
                         .onAppear() {
                             timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                                 withAnimation { scrollViewProxy.scrollTo(bottomID) }
                             }
                             timer_camera = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                                 updateCameraIfNeeded()
                             }
                             timer_text = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                                 updateTextIfNeeded()
                             }
                         }
                         .onDisappear() {
                             timer?.invalidate()
                             timer_camera?.invalidate()
                             timer_text?.invalidate()
                         }
                         VStack {
                             HStack {
                             }.background(Color.clear).lineLimit(1)
                             Spacer()
                         }
                         .padding()
                     }
                     .frame(height: traceGeom.size.height / 6)
                 }
            }.opacity(0.4)

            // Controls
            VStack {
            Spacer()

            HStack {
              HStack {
                  Button {
                      interman3d_model.testIHMCreate()
                  } label: {
                      Text("create")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }

                  Button {
                      nextCameraMode()
                  } label: {
                      Text("mode")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }

                  Button {
                      setCameraMode(.freeFlight)
                  } label: {
                      Text("free flight")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }

                  Button {
                      setCameraMode(.topManual)
                  } label: {
                      Text("top manual")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }

                  Button {
                      setCameraMode(.sideManual)
                  } label: {
                      Text("side manual")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }

                  Button {
                      setCameraMode(.topHostManual)
                  } label: {
                      Text("top host manual")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }

              }

              Spacer()
              Text("current: \(camera_model.camera_mode.rawValue)").foregroundColor(.white)
                
              Spacer()
                Button {
                    testCamera()
                    interman3d_model.testIHMUpdate()
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
