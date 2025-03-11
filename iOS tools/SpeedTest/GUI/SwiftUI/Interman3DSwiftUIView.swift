//
//  IntermanSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/03/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SceneKit
import iOSToolsMacros

/*
 Debugging camera movements:
 camera.removeAllActions()
 camera.removeAllAnimations()
 let foo = camera.presentation.pivot
 print(camera.pivot)
 print(camera.transform)
 print(camera.rotation)
 print(camera.position)
 print(camera.scale)
 print(camera.presentation.pivot)
 print(camera.presentation.transform)
 print(camera.presentation.rotation)
 print(camera.presentation.position)
 print(camera.presentation.scale)
 camera.constraints?.removeAll()
 print(camera.pivot)
 print(camera.transform)
 print(camera.rotation)
 print(camera.position)
 print(camera.scale)
 print(camera.presentation.pivot)
 print(camera.presentation.transform)
 print(camera.presentation.rotation)
 print(camera.presentation.position)
 print(camera.presentation.scale)
 */

private enum CameraMode : String {
    case topCentered, sideCentered, topHost, freeFlight
}

private class CameraModel: ObservableObject {
    static let shared = CameraModel()
    
    @Published private(set) var camera_mode: CameraMode = CameraMode.topCentered
    
    func setCameraMode(_ mode: CameraMode)  {
        camera_mode = mode
    }
    
    func nextCameraMode() {
        switch camera_mode {
        case .topCentered:
            camera_mode = .sideCentered
            
        case .sideCentered:
            camera_mode = .topHost
            
        case .topHost:
            camera_mode = .freeFlight
            
        case .freeFlight:
            camera_mode = .topCentered
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

class SetCameraConstraint: NSObject, CAAnimationDelegate {
    let camera: SCNNode
    let constraint: SCNConstraint
    
    init(camera: SCNNode, constraint: SCNConstraint) {
        self.camera = camera
        self.constraint = constraint
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        camera.constraints = [constraint]
    }
}

class RunAfterAnimation: NSObject, CAAnimationDelegate {
    let to_run: () -> ()
    
    init(_ to_run: @escaping () -> ()) {
        self.to_run = to_run
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        to_run()
    }
}

// https://sarunw.com/posts/swiftui-list-multiple-selection/
struct Filter: View {
    var master_view_controller: MasterViewController?
    @Binding var filter_active: Bool
    @Binding var filtering: Bool
    
    @State var doesClose: Bool = true
    @State private var multiSelection = Set<UUID>()

    @ObservedObject private var discovered_ports_model = DiscoveredPortsModel.shared
    var interman3d_model = Interman3DModel.shared

    // We create a init function to debug creations of this view
    /*
    init(master_view_controller: MasterViewController? = nil, filter_active: Binding<Bool>, multiSelection: Set<UUID> = Set<UUID>(), model: DiscoveredPortsModel = DiscoveredPortsModel.shared, interman3d_model: Interman3DModel = Interman3DModel.shared, hosts_model: DBMaster = DBMaster.shared) {
        self.master_view_controller = master_view_controller
        // Since filter_active is declared as @Binding, we need to use _filter_active to set its value
        self._filter_active = filter_active
        self.multiSelection = multiSelection
        self.discovered_ports_model = model
        self.interman3d_model = interman3d_model
//        self.hosts_model = hosts_model
        print("XXXX: INIT Filter")
    }*/
    
    func resetFilter() {
        filtering = false
        discovered_ports_model.deSelectAll()
        filter_active = false
        interman3d_model.resetOpacity()
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()

                if filtering {
                    Button(action: {
                        resetFilter()
                    }) {
                        Text("Reset filter")
                            .padding(8)
                            .foregroundColor(Color(COLORS.standard_background))
                            .background(content: {
                                Capsule()
                                    .foregroundColor(Color(COLORS.toolbar_background))
                                    .opacity(0.3)
                            })
                    }
                }

                /*
                // For debugging
                if filter_active {
                    Button("TEST add new node") {
                        var node = Node()
                        node.addName("NODE-\(Int.random(in: 0 ..< 1000000))")
                        node.addTcpPort(50)
                        _ = master_view_controller?.addNode(node)
                    }
                    .padding(8)
                    .foregroundColor(Color(COLORS.standard_background))
                    .background(content: {
                        Capsule()
                            .foregroundColor(Color(COLORS.toolbar_background))
                            .opacity(0.3)
                    })
                }
                */

                Button(action: {
                    filter_active.toggle()
                    if filter_active {
                        self.master_view_controller?.interman_view_controller?.disableTapGestureRecognizer()
                    } else {
                        self.master_view_controller?.interman_view_controller?.enableTapGestureRecognizer()

                        if discovered_ports_model.getSelectedPorts().isEmpty {
                            resetFilter()
                        }
                    }
                }) {
                    Text(filter_active ? "Hide list" : "Filter")
                        .padding(8)
                        .foregroundColor(Color(COLORS.standard_background))
                        .background(content: {
                            Capsule()
                                .foregroundColor(Color(COLORS.toolbar_background))
                                .opacity(0.3)
                        })
                }
            }

            HStack {
                Spacer()
                
                if filter_active {
                    // Removing the background of the scroll view: version that runs correctly on iOS 16 and more
                    List(discovered_ports_model.discovered_ports) { discovered_port in
                        HStack {
                            Button(action: {
                                // Il semble que la liste discovered_ports_model.discovered_ports puisse évoluer pendant qu'on parcours cette List
                                guard let idx = discovered_ports_model.getDiscoveredPortIndex(id: discovered_port.id) else { return }
                                let discovered_port = discovered_ports_model.discovered_ports[idx]

                                let hosts = DBMaster.getNodes(discovered_port.port)
                                for host in hosts {
                                    let node = interman3d_model.getB3DHost(host)
                                    guard let node else {
                                        _ = #saveTrace("node not found")
                                        break
                                    }
                                    // node.opacity = discovered_ports_model.discovered_ports[idx].is_selected ? 0.1 : 1.0
                                    node.runAction(SCNAction.fadeOpacity(to: discovered_ports_model.discovered_ports[idx].is_selected ? 0.3 : 1.0, duration: 1))
                                    master_view_controller?.addTrace("Filter: port \(discovered_port.port) exposed by \(host.concisefullDump())", level: .INFO)
                                }

                                discovered_ports_model.discovered_ports[idx].is_selected.toggle()

                            }) {
                                HStack {
                                    Image(systemName:
                                            (discovered_ports_model.getDiscoveredPortIndex(id: discovered_port.id) != nil) ? (
                                                discovered_ports_model.discovered_ports[discovered_ports_model.getDiscoveredPortIndex(id: discovered_port.id)!].is_selected ? "checkmark.circle.fill" : "circle") :
                                            "circle"
                                          )
                                        .foregroundColor(Color(COLORS.standard_background))
                                    Text(discovered_port.name).font(.caption)
                                        .foregroundColor(Color(COLORS.standard_background))
                                }
                            }
                            
                        }.listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                    .onAppear {
                        if filtering == false {
                            interman3d_model.resetOpacity(false)
                            discovered_ports_model.deSelectAll()
                        }
                    }
                    .frame(maxWidth: UIScreen.main.bounds.size.width / 2, maxHeight: UIScreen.main.bounds.size.height * 2 / 3)
                    .listStyle(PlainListStyle())
                    .background(Color(COLORS.toolbar_background), in: RoundedRectangle(cornerRadius: 28))
                    .opacity(0.8)

                    /* Removing the background of the scroll view on iOS 16 and more
                    if #available(iOS 16, *) {
                        List(model.contacts) { contact in
                            Text(contact.name).listRowBackground(Color.clear)
                        }
                        .frame(maxWidth: UIScreen.main.bounds.size.width / 2, maxHeight: UIScreen.main.bounds.size.height * 2 / 3)
                        .background(Color(COLORS.toolbar_background), in: RoundedRectangle(cornerRadius: 28))
                        .scrollContentBackground(.hidden)
                        .opacity(0.8)
                    } else {
                        // Removing the background of the scroll view on iOS 15
                        List(model.contacts) { contact in
                            Text(contact.name).listRowBackground(Color.clear)
                        }
                        .frame(maxWidth: UIScreen.main.bounds.size.width / 2, maxHeight: UIScreen.main.bounds.size.height * 2 / 3)
                        .background(Color(COLORS.toolbar_background), in: RoundedRectangle(cornerRadius: 28))
                        .onAppear {
                            // On iOS 15, List are implemented with UITableView, therefore the equivalent of .scrollContentBackground(.hidden) is the following line.
                            // Note that it applies everywhere in the app once it is used here.
                            UITableView.appearance().backgroundColor = .clear
                        }
                        .opacity(0.8)
                    }
                    */
                }
            }
        }
        .padding([.horizontal], 24)
    }
}

struct Interman3DSwiftUIView: View {
    weak var master_view_controller: MasterViewController?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    let scale_zoom = UIDevice.current.userInterfaceIdiom == .phone ? 2.0 : 1.0
    
    @State private var free_flight_active: Bool = false
    @State private var auto_rotation_active: Bool = false
    @State private var auto_rotation_button_toggle: Bool = false
    
    @State private var timer_camera: Timer?
    @State private var timer_text: Timer?
    @State private var timer_auto_rotation_button: Timer?
    @State private var timer: Timer?
    
    @State private var disable_buttons = false
    @State private var disable_auto_rotation_button = false
    @State private var disable_traces = true

    @ObservedObject private var interman3d_model = Interman3DModel.shared
    @ObservedObject private var model = TracesViewModel.shared

    @ObservedObject private var discovered_ports_model = DiscoveredPortsModel.shared
    
    @ObservedObject private var camera_model = CameraModel.shared
    private let camera: SCNNode
    private let sphere: SCNNode
    private let sphere2: SCNNode // only for debugging
    private let scene: SCNScene
    
    private var render_delegate = RenderDelegate()
    
    private let button_size_factor = UIDevice.current.userInterfaceIdiom == .phone ? 1.0 : 1.2
    
    private func createAxes() {
        let axes = ComponentTemplates.createAxes(0.2)
        axes.name = "axes"
        scene.rootNode.addChildNode(axes)
    }
    
    private func dropAxes() {
        scene.rootNode.childNode(withName: "axes", recursively: true)?.removeFromParentNode()
    }
    
    init() {
        scene = Interman3DModel.shared.scene
        camera = Interman3DModel.shared.scene.rootNode.childNode(withName: "camera", recursively: true)!
        sphere = scene.rootNode.childNode(withName: "sphere", recursively: true)!
        sphere2 = scene.rootNode.childNode(withName: "sphere2", recursively: true)!
        
        camera.camera!.usesOrthographicProjection = true
        camera.camera!.automaticallyAdjustsZRange = true
        
        // Debug: axes
        // createAxes()
        
        // Set camera initial position
        camera.parent!.scale = SCNVector3(2 * scale_zoom, 2 * scale_zoom, 2 * scale_zoom)
        camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
        let lookAtConstraint = SCNLookAtConstraint(target: sphere)
        lookAtConstraint.isGimbalLockEnabled = false
        camera.constraints = [lookAtConstraint]
        
        // Changer la couleur du ciel
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
        // let sky = scene.background.contents as! MDLSkyCubeTexture
        // sky.groundColor = .init(red: 1, green: 1, blue: 1, alpha: 1) // COLORS.leftpannel_bg.cgColor
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
            
            // A SUPPRIMER - pour débugger
            /*
             print(horizontalSizeClass)
             if UIDevice.current.userInterfaceIdiom == .phone {
             print("iPhone")
             } else {
             print("not iPhone")
             }*/
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
        let prev_mode = camera_model.getCameraMode()
        
        camera_model.setCameraMode(mode)
        
        switch camera_model.camera_mode {
        case .topCentered:
            // Set constraint to look at sphere
            // Note: it is not possible to have a smooth transition between look at constraints but it can be done simply by having a smooth transition of the position of the object this contraint follows
            
            disable_auto_rotation_button = false
            
            if prev_mode == .freeFlight { // OK
                free_flight_active = false
                dropAxes()
                
                let lookAtConstraint = SCNLookAtConstraint(target: sphere)
                lookAtConstraint.isGimbalLockEnabled = false
                camera.constraints = [lookAtConstraint]
                
                camera.transform = SCNMatrix4MakeTranslation(0, 1, 2)
                
                camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
                
                disable_buttons = true
                let animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 5, 0)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({ disable_buttons = false })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
            }
            
            if prev_mode == .sideCentered { // OK
                // Constraint is already sphere
                
                camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
                
                disable_buttons = true
                let animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 5, 0)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({ disable_buttons = false })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
            }
            
            if prev_mode == .topHost { // OK
                // No constraint
                
                camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
                
                disable_buttons = true
                var animation = CABasicAnimation(keyPath: "pivot")
                animation.fromValue = camera.presentation.pivot
                animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
                animation.duration = 1
                let lookAtConstraint = SCNLookAtConstraint(target: sphere)
                lookAtConstraint.isGimbalLockEnabled = false
                animation.delegate = SetCameraConstraint(camera: camera, constraint: lookAtConstraint)
                camera.addAnimation(animation, forKey: "campivot")
                
                animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 5, 0)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({ disable_buttons = false })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
            }
            
        case .sideCentered:
            // Set constraint to look at sphere
            
            disable_auto_rotation_button = false
            
            if prev_mode == .freeFlight { // OK
                dropAxes()
                free_flight_active = false
                
                camera.parent!.scale = SCNVector3(2 * scale_zoom, 2 * scale_zoom, 2 * scale_zoom)
                
                let lookAtConstraint = SCNLookAtConstraint(target: sphere)
                lookAtConstraint.isGimbalLockEnabled = false
                camera.constraints = [lookAtConstraint]
                
                camera.transform = SCNMatrix4MakeTranslation(0, 1, 2)
            }
            
            if prev_mode == .topCentered { // OK
                // Constraint is already sphere
                
                disable_buttons = true
                camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
                
                let animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 1, 2)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({ disable_buttons = false })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 1, 2)
            }
            
            if prev_mode == .topHost { // OK
                // No constraint
                
                disable_auto_rotation_button = false
                
                camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
                disable_buttons = true
                
                var animation = CABasicAnimation(keyPath: "pivot")
                animation.fromValue = camera.presentation.pivot
                animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
                animation.duration = 1
                let lookAtConstraint = SCNLookAtConstraint(target: sphere)
                lookAtConstraint.isGimbalLockEnabled = false
                animation.delegate = SetCameraConstraint(camera: camera, constraint: lookAtConstraint)
                camera.addAnimation(animation, forKey: "campivot")
                
                animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 5, 0)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({
                    // Top to side
                    let animation = CABasicAnimation(keyPath: "transform")
                    animation.fromValue = camera.presentation.transform
                    animation.toValue = SCNMatrix4MakeTranslation(0, 1, 2)
                    animation.duration = 1
                    animation.delegate = RunAfterAnimation({ disable_buttons = false })
                    camera.addAnimation(animation, forKey: "camtransform")
                    camera.transform = SCNMatrix4MakeTranslation(0, 1, 2)
                })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
            }
            
        case .topHost:
            disable_auto_rotation_button = false
            
            if prev_mode == .freeFlight { // OK
                dropAxes()
                free_flight_active = false
                disable_buttons = true
                
                camera.parent!.scale = SCNVector3(1.5 * scale_zoom, 1.5 * scale_zoom, 1.5 * scale_zoom)
                
                let lookAtConstraint = SCNLookAtConstraint(target: sphere)
                lookAtConstraint.isGimbalLockEnabled = false
                camera.constraints = [lookAtConstraint]
                
                camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)

                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    camera.constraints?.removeAll()
                    
                    // Since we removed the contraint, we must set the pivot
                    var animation = CABasicAnimation(keyPath: "pivot")
                    animation.fromValue = camera.presentation.pivot
                    animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
                    animation.duration = 1
                    animation.delegate = RunAfterAnimation({ disable_buttons = false })
                    camera.addAnimation(animation, forKey: "campivot")
                    camera.pivot = camera.presentation.pivot
                    
                    animation = CABasicAnimation(keyPath: "transform")
                    animation.fromValue = camera.presentation.transform
                    animation.toValue = SCNMatrix4MakeTranslation(0.5, 5, 0)
                    animation.duration = 1
                    camera.addAnimation(animation, forKey: "camtransform")
                    camera.transform = SCNMatrix4MakeTranslation(0.5, 5, 0)
                }
            }
            
            if prev_mode == .topCentered { // OK
                camera.parent!.runAction(SCNAction.scale(to: 1.5 * scale_zoom, duration: 0.5))
                disable_buttons = true
                
                camera.constraints?.removeAll()
                
                // Since we removed the contraint, we must set the pivot
                var animation = CABasicAnimation(keyPath: "pivot")
                animation.fromValue = camera.presentation.pivot
                animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({ disable_buttons = false })
                camera.addAnimation(animation, forKey: "campivot")
                camera.pivot = camera.presentation.pivot
                
                animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0.5, 5, 0)
                animation.duration = 1
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0.5, 5, 0)
            }
            
            if prev_mode == .sideCentered { // OK
                // Constraint is sphere
                
                camera.parent!.runAction(SCNAction.scale(to: 1.5 * scale_zoom, duration: 0.5))
                disable_buttons = true
                
                // Side to top
                var animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 5, 0)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({
                    // Top to top host
                    camera.constraints?.removeAll()
                    
                    // Since we removed the contraint, we must set the pivot
                    animation = CABasicAnimation(keyPath: "pivot")
                    animation.fromValue = camera.presentation.pivot
                    animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
                    animation.duration = 1
                    animation.delegate = RunAfterAnimation({ disable_buttons = false })
                    camera.addAnimation(animation, forKey: "campivot")
                    camera.pivot = camera.presentation.pivot
                    
                    animation = CABasicAnimation(keyPath: "transform")
                    animation.fromValue = camera.presentation.transform
                    animation.toValue = SCNMatrix4MakeTranslation(0.5, 5, 0)
                    animation.duration = 1
                    camera.addAnimation(animation, forKey: "camtransform")
                    camera.transform = SCNMatrix4MakeTranslation(0.5, 5, 0)
                    
                })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
            }
            
        case .freeFlight:
            disable_auto_rotation_button = true
            
            if prev_mode == .sideCentered {
                free_flight_active = true
                auto_rotation_active = false
                createAxes()
                
                camera.constraints?.removeAll()
            }
            
            if prev_mode == .topCentered {
                // Constraint is already sphere
                
                camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
                disable_buttons = true
                
                let animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 1, 2)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({
                    free_flight_active = true
                    disable_buttons = false
                    createAxes()
                    camera.constraints?.removeAll()
                })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 1, 2)
            }
            
            if prev_mode == .topHost {
                // No constraint
                
                camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
                disable_buttons = true
                
                var animation = CABasicAnimation(keyPath: "pivot")
                animation.fromValue = camera.presentation.pivot
                animation.toValue = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
                animation.duration = 1
                let lookAtConstraint = SCNLookAtConstraint(target: sphere)
                lookAtConstraint.isGimbalLockEnabled = false
                animation.delegate = SetCameraConstraint(camera: camera, constraint: lookAtConstraint)
                camera.addAnimation(animation, forKey: "campivot")
                
                animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = camera.presentation.transform
                animation.toValue = SCNMatrix4MakeTranslation(0, 5, 0)
                animation.duration = 1
                animation.delegate = RunAfterAnimation({
                    // Top to side
                    let animation = CABasicAnimation(keyPath: "transform")
                    animation.fromValue = camera.presentation.transform
                    animation.toValue = SCNMatrix4MakeTranslation(0, 1, 2)
                    animation.duration = 1
                    animation.delegate = RunAfterAnimation({
                        free_flight_active = true
                        disable_buttons = false
                        createAxes()
                        camera.constraints?.removeAll()
                    })
                    camera.addAnimation(animation, forKey: "camtransform")
                    camera.transform = SCNMatrix4MakeTranslation(0, 1, 2)
                })
                camera.addAnimation(animation, forKey: "camtransform")
                camera.transform = SCNMatrix4MakeTranslation(0, 5, 0)
            }
        }
    }
    
    private func updateTextIfNeeded() {
        interman3d_model.scheduledTextUpdate()
    }
    
    private func updateCameraIfNeeded() {
        if auto_rotation_active {
            let host = interman3d_model.getLowestNodeAngle(getCameraAngle())
            rotateCamera(-host.getAngle(), smooth: true, duration: 1)
        }
    }
    
    // Get scale factor
    // The parent is scaled, not the camera itself
    func getCameraScaleFactor() -> Float {
        return camera.parent!.simdScale.x
    }
    
    // Set scale factor
    func scaleCamera(_ factor: Float) {
        camera.parent!.simdScale = SIMD3<Float>(factor, factor, factor)
    }
    
    func resetCamera() {
        if let local_node = DBMaster.shared.getLocalNodeIfExists() {
            setSelectedHost(local_node)
        } else {
            rotateCamera(0, smooth: true, duration: 1)
        }
        
        if camera_model.getCameraMode() == .topHost {
            camera.parent!.runAction(SCNAction.scale(to: 1.5 * scale_zoom, duration: 0.5))
        } else  {
            camera.parent!.runAction(SCNAction.scale(to: 2 * scale_zoom, duration: 0.5))
        }
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
    
    let space_between_buttons: CGFloat = 5
    
    var body: some View {
        ZStack {
            // 3D view
            if free_flight_active == true {
                SceneView(
                    scene: scene,
                    options: [.allowsCameraControl],
                    delegate: render_delegate
                )
                .edgesIgnoringSafeArea(.all)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 1)))
            } else {
                SceneView(
                    scene: scene,
                    options: SceneView.Options(),
                    delegate: render_delegate
                )
                .edgesIgnoringSafeArea(.all)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 1)))
            }
            
            // Traces
            VStack {
                if disable_traces == false {
                    GeometryReader { traceGeom in
                        VStack {
                            ScrollViewReader { scrollViewProxy in
                                ZStack {
                                    ScrollView {
                                        ZStack {
                                            LazyVStack(alignment: .leading, spacing: 0) {
                                                Spacer().id(topID)
                                                ForEach(0 ..< model.traces.count - 1, id: \.self) { i in
                                                    Text(model.traces[i])
                                                        .font(Font.custom("San Francisco", size: 10).monospacedDigit())
                                                    // .font(.footnote)
                                                        .lineLimit(nil)
                                                        .foregroundColor(Color(COLORS.standard_background.darker().darker()))
                                                }
                                                Text(model.traces.last!)
                                                //                                         .font(.footnote)
                                                    .font(Font.custom("San Francisco", size: 10).monospacedDigit())
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
                                        // Avoid situations when buttons are definitely disabled
                                        disable_buttons = false
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
                                .background(content: {
                                    Rectangle().scale(1.1)
                                        .foregroundColor(Color(COLORS.toolbar_background))
                                        .opacity(0.1)
                                })
                            }
                            
                            HStack {
                                Spacer()
                                Filter(master_view_controller: self.master_view_controller, filter_active: $discovered_ports_model.filter_active, filtering: $discovered_ports_model.filtering).padding([.vertical], 10)
//                                    .onAppear() {
//                                        discovered_ports_model.filtering = true
//                                    }
                            }
                            
                        }
                        
                    }
                } else {
                    HStack {
                        Spacer()
                        Filter(master_view_controller: self.master_view_controller, filter_active: $discovered_ports_model.filter_active, filtering: $discovered_ports_model.filtering).padding([.vertical], 10)
//                            .onAppear() {
//                                discovered_ports_model.filtering = true
//                            }
                    }
                    Spacer()
                }
            }
            
            // Controls
            VStack {
                Spacer()
                HStack {
                    HStack {
                        Spacer()
                        HStack(alignment: .center, spacing: 0) {
                            Button {
                                // interman3d_model.testIHMCreate()
                                master_view_controller!.update_pressed()
                            } label: {
                                //                      if horizontalSizeClass == .regular { Text("create") }
                                Image(systemName: "repeat")
                                    .resizable()
                                    .frame(width: 25 * button_size_factor, height: 20 * button_size_factor)
                                    .foregroundColor(Color(COLORS.standard_background))
                                // Let the background clickable
                                    .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                    .padding(space_between_buttons)
                            }//.background(Color.blue)
                            
                            Button {
                                master_view_controller!.interman_view_controller?.hostingViewController.rootView.resetCamera()
                            } label: {
                                Image(systemName: "slowmo")
                                    .resizable()
                                    .frame(width: 25 * button_size_factor, height: 25 * button_size_factor)
                                    .foregroundColor((camera_model.camera_mode == .freeFlight) ? nil : Color(COLORS.standard_background))
                                // Let the background clickable
                                    .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                    .padding(space_between_buttons)
                            }.disabled(camera_model.camera_mode == .freeFlight)
                                //.background(Color.blue)
                            
                            Spacer().frame(width: 25)
                            
                            Button {
                                setCameraMode(.freeFlight)
                                auto_rotation_active = false
                            } label: {
                                //                      if horizontalSizeClass == .regular { Text("free flight") }
                                Image(systemName: "rotate.3d")
                                    .resizable()
                                    .frame(width: 25 * button_size_factor, height: 25 * button_size_factor)
                                    .foregroundColor((disable_buttons || camera_model.camera_mode == .freeFlight) ? nil : Color(COLORS.standard_background))
                                // Let the background clickable
                                    .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                    .padding(space_between_buttons)
                            }.disabled(disable_buttons || camera_model.camera_mode == .freeFlight)
                            
                            Button {
                                setCameraMode(.sideCentered)
                            } label: {
                                //                      if horizontalSizeClass == .regular { Text("side") }
                                //                      Image(systemName: "cube.fill").imageScale(.large)
                                Image("icon-3D-cube").renderingMode(.template).resizable()
                                    .foregroundColor((disable_buttons || camera_model.camera_mode == .sideCentered) ? nil : Color(COLORS.standard_background))
                                    .frame(width: 30 * button_size_factor, height: 25 * button_size_factor)
                                // Let the background clickable
                                    .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                    .padding(space_between_buttons)
                            }.disabled(disable_buttons || camera_model.camera_mode == .sideCentered)
                            
                            Button {
                                setCameraMode(.topCentered)
                            } label: {
                                //                      if horizontalSizeClass == .regular { Text("top") }
                                Image("icon-2D-top").renderingMode(.template).resizable()
                                    .foregroundColor((disable_buttons || camera_model.camera_mode == .topCentered) ? nil : Color(COLORS.standard_background))
                                    .frame(width: 25 * button_size_factor, height: 25 * button_size_factor)
                                // Let the background clickable
                                    .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                    .padding(space_between_buttons)
                            }.disabled(disable_buttons || camera_model.camera_mode == .topCentered)
                            
                            // Les animations vers .topHost se finissent sans qu'on ne voit plus rien sur iPad et MacOS, donc on supprime ce bouton sur ces plate-formes
                            if ProcessInfo.processInfo.isMacCatalystApp == false && UIDevice.current.userInterfaceIdiom != .pad {
                                Button {
                                    setCameraMode(.topHost)
                                } label: {
                                    //                      if horizontalSizeClass == .regular { Text("top host") }
                                    Image("icon-2D-left").renderingMode(.template).resizable()
                                        .foregroundColor((disable_buttons || camera_model.camera_mode == .topHost) ? nil : Color(COLORS.standard_background))
                                        .frame(width: 25 * button_size_factor, height: 25 * button_size_factor)
                                    // Let the background clickable
                                        .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                        .padding(space_between_buttons)
                                }.disabled(disable_buttons || camera_model.camera_mode == .topHost)
                            }
                            
                            Spacer().frame(width: 25)
                            
                            Button {
                                disable_traces.toggle()
                            } label: {
                                ZStack {
                                    if disable_traces {
                                        Image(systemName: "line.diagonal").resizable()
                                            .frame(width: 16 * button_size_factor, height: 16 * button_size_factor)
                                            .foregroundColor(Color(COLORS.standard_background))
                                        
                                        Image(systemName: "line.diagonal").resizable()
                                            .rotationEffect(.degrees(90))
                                            .frame(width: 16 * button_size_factor, height: 16 * button_size_factor)
                                            .foregroundColor(Color(COLORS.standard_background))
                                    }
                                    
                                    Image(systemName: "text.justify")
                                        .resizable()
                                        .frame(width: 20 * button_size_factor, height: 20 * button_size_factor)
                                        .foregroundColor(Color(COLORS.standard_background))
                                    // Let the background clickable
                                        .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                        .padding(space_between_buttons)
                                }
                            }
                            
                            Button {
                                auto_rotation_active.toggle()
                                if auto_rotation_active == true { resetCameraTimer() }
                            } label: {
                                //                    Text("auto rotation").foregroundColor(auto_rotation_active ? .red : .blue)
                                Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                                    .resizable()
                                    .frame(width: 30 * button_size_factor, height: 25 * button_size_factor)
                                    .foregroundColor(camera_model.camera_mode == .freeFlight ? nil : (auto_rotation_active ? (auto_rotation_button_toggle ? Color(COLORS.standard_background) : Color(COLORS.standard_background.lighter().lighter().lighter().lighter().lighter().lighter().lighter().lighter().lighter())) : Color(COLORS.standard_background)))
                                // Let the background clickable
                                    .background { Rectangle().foregroundStyle(Color(COLORS.toolbar_background)).opacity(0.1) }
                                    .padding(space_between_buttons)
                            }.disabled(disable_auto_rotation_button || camera_model.camera_mode == .freeFlight)
                        }.padding(0)
                            .background(content: {
                                Capsule()
                                    .foregroundColor(Color(COLORS.toolbar_background))
                                    .opacity(0.3)
                                
                            })
                    }
                }
//                .padding(8)
                .cornerRadius(14)
                .padding(12)
            }
            
        }.background(Color(COLORS.chart_bg))
            .onAppear() {
                timer_auto_rotation_button = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                    auto_rotation_button_toggle.toggle()
                }
                
                timer_camera = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                    updateCameraIfNeeded()
                }
                timer_text = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                    updateTextIfNeeded()
                }
                // Avoid situations when buttons are definitely disabled
                disable_buttons = false
                
            }
            .onDisappear() {
                timer_auto_rotation_button?.invalidate()
                timer_camera?.invalidate()
                timer_text?.invalidate()
            }
        
    }
}


