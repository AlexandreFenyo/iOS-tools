//
//  IntermanSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/03/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SceneKit

// true pour débugger
private let free_flight = true

class RenderDelegate: NSObject, SCNSceneRendererDelegate {
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

    @ObservedObject var interman3d_model = Interman3DModel.shared
    @ObservedObject var model = TracesViewModel.shared

    private let camera: SCNNode
    let scene: SCNScene
    private var render_delegate = RenderDelegate()
    
    init() {
        scene = SCNScene(named: "Interman 3D Scene.scn")!
        Interman3DModel.shared.scene = scene
        camera = scene.rootNode.childNode(withName: "camera", recursively: true)!
        camera.camera!.usesOrthographicProjection = true
        camera.camera!.automaticallyAdjustsZRange = true

        if free_flight {
            camera.transform = SCNMatrix4MakeRotation(-.pi / 2, 1, 0, 0)
            // scene.rootNode.addChildNode(ComponentTemplates.createAxes(0.2))
        } else {
            camera.pivot = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
        }

        camera.position = SCNVector3(0, 5, 0)

        camera.scale = SCNVector3(2, 2, 2)

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
    
    func getCameraAngle() -> Float {
        // Note that Euler angles (0, u, 0) and Euler angles (π, π-u, π) correspond to the same orientation
        return Interman3DModel.normalizeAngle(camera.eulerAngles.x == 0 ? camera.eulerAngles.y : (-camera.eulerAngles.y + .pi))
    }

    // Set camera absolute orientation value
    func rotateCamera(_ angle: Float, smooth: Bool) {
        if free_flight { return }
        if smooth {
            var duration = Interman3DModel.normalizeAngle(getCameraAngle() - angle)
            if duration > .pi { duration = 2 * .pi - duration }
            // duration is between 0 (no movement) and 1 sec (half turn)
            camera.removeAction(forKey: "rotation")
            camera.runAction(SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: Double(duration) / .pi, usesShortestUnitArc: true), forKey: "rotation")
       } else {
            camera.runAction(SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0))
        }
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
        rotateCamera(0, smooth: true)
        camera.runAction(SCNAction.scale(to: 2, duration: 0.5))
    }

    func testQuat() {
    }
    
    func setSelectedHost(_ host: Node) {
        guard let node = interman3d_model.getB3DHost(host) else { return }
        let new_camera_angle = -node.getAngle()
        rotateCamera(new_camera_angle, smooth: true)
    }
    
    // .allowsCameraControl: if allowed, the user takes control of the camera, therefore not any pan or pinch gestures will be fired
    let scene_view_options = free_flight ? [ .allowsCameraControl ] : SceneView.Options()

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
            SceneView(
                scene: scene,
                options: scene_view_options,
                delegate: render_delegate
            )
            .edgesIgnoringSafeArea(.all)

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
                         }
                         .onDisappear() {
                             timer?.invalidate()
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
              }

              Spacer()
              Text("salut").foregroundColor(.white)
              Spacer()
                Button {
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
