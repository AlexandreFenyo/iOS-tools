//
//  Interman3DManager.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 19/03/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

import Foundation
import SwiftUI
import SceneKit

// Blender
// https://emily-45402.medium.com/building-3d-assets-in-blender-for-ios-developers-c47535755f18

// Attention : les initialiseurs de tableaux sont consommateurs de CPU, il faut plutôt passer les 4 colonnes plutôt qu'un tableau de colonnes à une fonction qui propose les deux

// rotations :
// avec quaternions : https://stackoverflow.com/questions/49601997/is-there-a-metal-library-function-to-create-a-simd-rotation-matrix
//   var piv0 = simd_float4x4(simd_quatf(angle: GLKMathDegreesToRadians(10), axis: SIMD3(0, 1, 0)))
//   b3d_test?.simdPivot = piv0
// avec GL : https://developer.apple.com/documentation/glkit/1488683-glkmatrix4makezrotation
//   rad, x, y, z
//   var piv1 = simd_float4x4(matrix: GLKMatrix4MakeRotation(GLKMathDegreesToRadians(10), 0, 1, 0))
//   b3d_test?.simdPivot = piv1
// translations :
//   var x: simd_float4x4 = matrix_identity_float4x4
//   x[3, 0] = -1
//   x[3, 2] = -1
// simdPivot to pivot: SCNMatrix4(simdPivot)
// degress to radians: GLKMathDegreesToRadians(-90)
// PI : M_2_PI, M_PI_2, Float.pi, .pi

// simdPivot = matrix_identity_float4x4
// let transf = SCNMatrix4Identity

// SIMDx et SCNVectorx :
// text_node.simdScale = SIMD3(0.1, 0.1, 0.1)
// text_node.scale = SCNVector3(0.1, 0.1, 0.1)

// actions vs animations

// matrices de translation et rotation :
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/CoreAnimationBasics/CoreAnimationBasics.html#//apple_ref/doc/uid/TP40004514-CH2-SW3

 // créer des matrices : doc de SCNMatrix4

// gestures:
// https://stackoverflow.com/questions/28006040/tap-select-node-in-scenekit-swift
// https://www.appcoda.com/learnswiftui/swiftui-gestures.html
// Chart.swift

// multiplications de matrices :
// //            return SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, -foo / 2, 0), SCNMatrix4Mult(SCNMatrix4MakeScale(1, foo, 1), SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)))

            // bug : devraient avoir le même effet, mais ce n'est pas le cas
//            let transf = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, -5 / 2, 0), SCNMatrix4Mult(SCNMatrix4MakeScale(1, 5, 1), SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)))
//            let transf = SCNMatrix4MakeTranslation(0, -5 / 2, 0)
//            let transf = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
//            let transf = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, -5 / 2, 0), SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0))
//            let transf = SCNMatrix4Mult(SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0), SCNMatrix4MakeTranslation(0, -5 / 2, 0))
//            let transf = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, -5 / 2, 0), SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0))
//
//            let transf = SCNMatrix4(simd_float4x4(SCNMatrix4MakeTranslation(0, -5 / 2, 0)) * (simd_float4x4(SCNMatrix4MakeScale(1, 5, 1)) * simd_float4x4(SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0))))
//            let transf = SCNMatrix4(simd_float4x4(SCNMatrix4MakeTranslation(0, -5 / 2, 0))) // * simd_float4x4(SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0))))
//let transf = SCNMatrix4(simd_float4x4(SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)))
            //let transf = SCNMatrix4(simd_float4x4(SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)))
//            let transf = SCNMatrix4(simd_float4x4(SCNMatrix4MakeTranslation(0, -5 / 2, 0)) * simd_float4x4(SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)))

// https://developer.apple.com/documentation/scenekit/scnnode/1407990-convertposition

/*
guard let bar_host = DBMaster.shared.sections[.localhost]?.nodes.first else {
    print("\(#function): warning, localhost not found")
    return
}
guard let bar_node = getB3DHost(bar_host) else {
    print("\(#function): warning, localhost is not backed by a 3D node")
    return
}
print("IHM create localhost:")
print("world: \(bar_node.worldPosition)")
print("pivot: \(bar_node.pivot)")
print("transf: \(bar_node.transform)")
*/

// rajouter un repère :
// link_node_draw.addChildNode(ComponentTemplates.createAxes(5))

// avoir un rendu filaire :
// link_node_draw.geometry?.firstMaterial?.fillMode = .lines

// Add a box around the text node:
// let (min, max) = text_node.boundingBox
// let geoBox = SCNBox(width: CGFloat(max.x - min.x), height: CGFloat(max.y - min.y), length: CGFloat(max.z - min.z), chamferRadius: 0)
// geoBox.firstMaterial!.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
// let boxNode = SCNNode(geometry: geoBox)
// boxNode.position = SCNVector3Make((max.x - min.x) / 2 + min.x, (max.y - min.y) / 2 + min.y, 0);
// text_node.addChildNode(boxNode)

// liste des modèles 3D nécessaires :
// X- Apple TV
// - serveur DNS
// X- iPad
// X- iPhone
// - Mac : ssh + _airplay._tcp.
// - serveur de stockage : _smb._tcp. ou TCP/445, _adisk._tcp. ou _smb._tcp. ou TCP/445
// X- imprimante-scanner : _pdl-datastream._tcp., _scanner._tcp., TCP/9100 (printer), TCP/9500 (scan)
// X- imprimante sans scanner
// - serveur web : TCP/80
// kerberos ?
// - Hue (domotique)
// - IoT avec audio
// X- audio (mais pas IoT, ex: Marantz)
// X- routeur
// X- laptop

struct ComponentTemplates {
    // Pour tester des modèles 3D
//    public static let standard = SCNScene(named: "test.scn")!.rootNode

    // https://sketchfab.com/3d-models/mini-macbook-pro-2b054523279747c8b5b2e5ed9ea7b311
    // https://sketchfab.com/3d-models/08-printer-householdpropschallenge-a11b8e0bfc8741f08472c09b10202c75
    // https://sketchfab.com/3d-models/printer-household-props-8-39c75da7fbd34187acd1750d7ac41142
    // https://sketchfab.com/3d-models/old-printer-low-poly-d4a6b284b2984c59ae2a3a1bdeb059cf
    // https://sketchfab.com/3d-models/apple-tv-4k-3rdgen-wifi-ethernet-b223af0890f4406087b070e0532f85be
    // https://sketchfab.com/3d-models/c8300-1n1s-4t2x-64f3ae889fda4a8f80ab229baf6060b7
    // desktop: https://sketchfab.com/3d-models/desktop-pc-7030da42a907455ea98fabedca0a5192
    // https://sketchfab.com/3d-models/iphone-13-pro-concept-43bddf623d24406aae61c8f3ba516e3d#download
    // https://sketchfab.com/3d-models/apple-homepod-2229c164afd84b32aa23d6319a702c1f
    // https://sketchfab.com/3d-models/realistic-speaker-277db5efa378494882aaa820abb84437
    // https://sketchfab.com/3d-models/apple-ipad-pro-e5ffb3c80b2d4d6690249f8ee2bdafbe
    // https://sketchfab.com/3d-models/server-scayle-08987ebeb0b04a8ca6179344330ceec7#download
    // https://sketchfab.com/3d-models/server-v2-console-f24594ece9634cec9c1210c041838371#download
    // https://sketchfab.com/3d-models/apple-mac-mini-m1-79f1f864089d423fb06d220fe2085c71
    // https://sketchfab.com/3d-models/google-home-0e9d0a055dde4d83b7fd53d8b7465916
    // chromecast: https://www.thingiverse.com/thing:4176450
    // https://sketchfab.com/3d-models/laptop-9a960986f0cc49f99a0afdfb486ec859#download

  public static let standard = SCNScene(named: "Interman 3D Standard Component.scn")!.rootNode
//    public static let standard = SCNScene(named: "laptop.scn")!.rootNode

    public static let chromecast = SCNScene(named: "chromecast.scn")!.rootNode
    public static let googlehome = SCNScene(named: "googlehome.scn")!.rootNode
    public static let homepod = SCNScene(named: "homepod.scn")!.rootNode
    public static let macmini = SCNScene(named: "macmini.scn")!.rootNode
    public static let ovh = SCNScene(named: "ovh.scn")!.rootNode
    public static let server = SCNScene(named: "server.scn")!.rootNode
    public static let speaker = SCNScene(named: "speaker.scn")!.rootNode
    public static let iPhone = SCNScene(named: "iPhone.scn")!.rootNode
    public static let iPad = SCNScene(named: "iPad.scn")!.rootNode
    public static let router = SCNScene(named: "router.scn")!.rootNode
//    public static let laptop = SCNScene(named: "laptop.scn")!.rootNode
    public static let laptop2 = SCNScene(named: "laptop2.scn")!.rootNode
    public static let printer = SCNScene(named: "printer2.scn")!.rootNode
    public static let atv = SCNScene(named: "atv.scn")!.rootNode
    public static let axes = SCNScene(named: "Repère.scn")!.rootNode

    public static func createAxes(_ scale: Float) -> SCNNode {
        let new_axes = axes.clone()
        new_axes.scale = SCNVector3(scale, scale, scale)
        return new_axes
    }
}

// Base class for 3D objects in a circle
class B3D : SCNNode {
    static let default_scale: Float = 0.1
    private let sub_node = SCNNode()
    private var object_sub_node_ref: SCNNode
    private var object_sub_node: SCNNode
    private var angle: Float = 0
    private var link_refs = Set<Link3D>()

    init(_ scn_node: SCNNode) {
        sub_node.simdScale = simd_float3(B3D.default_scale, B3D.default_scale, B3D.default_scale)
        object_sub_node_ref = scn_node
        object_sub_node = object_sub_node_ref.clone()
        sub_node.addChildNode(object_sub_node)
        super.init()
        addChildNode(sub_node)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateModelScale() {
        let nhosts = Interman3DModel.shared.getNHosts()
        let space = 0.8 * 2 * .pi / (Float(max(nhosts, 15)) * B3D.default_scale)
        let (bb_min, bb_max) = object_sub_node.boundingBox
        let extend = SCNVector3(bb_max.x - bb_min.x, bb_max.y - bb_min.y, bb_max.z - bb_min.z)
        let max_extend = max(extend.x, extend.z)
        object_sub_node.pivot = SCNMatrix4MakeTranslation(0, bb_min.y, 0)
        object_sub_node.scale = SCNVector3(space * 1 / max_extend, space * 1 / max_extend, space * 1 / max_extend)
    }
    
    func updateModel(_ scn_node: SCNNode) {
        if object_sub_node_ref === scn_node { return }
        object_sub_node_ref = scn_node
        object_sub_node.removeFromParentNode()
        object_sub_node = object_sub_node_ref.clone()

        updateModelScale()
        
        sub_node.addChildNode(object_sub_node)
    }
    
    func addLinkRef(_ link: Link3D) {
        link_refs.insert(link)
    }

    func removeLinkRef(_ link: Link3D) {
        link_refs.remove(link)
    }

    func getLinks() -> Set<Link3D> {
        link_refs
    }
    
    func getLinks(with: B3D) -> Set<Link3D> {
        link_refs.filter { $0.getEnds().contains(with) }
    }

    func getLink3DScanNodes() -> Set<Link3DScanNode> {
        link_refs.filter { $0 is Link3DScanNode } as! Set<Link3DScanNode>
    }
    
    fileprivate func addSubChildNode(_ child: SCNNode) {
        sub_node.addChildNode(child)
    }
    
    fileprivate func getSubNode() -> SCNNode {
        sub_node
    }
    
    func getAngle() -> Float {
        angle
    }
    
    fileprivate func firstAnim(_ angle: Float) {
        self.angle = Interman3DModel.normalizeAngle(angle)
        
        let rot = simd_float4x4(simd_quatf(angle: angle, axis: SIMD3(0, 1, 0)))
        var transl = matrix_identity_float4x4
        transl[3, 0] = -1
        simdPivot = transl * rot
        let animation = CABasicAnimation(keyPath: "pivot")
        animation.fromValue = SCNMatrix4(rot)
        animation.toValue = SCNMatrix4(transl * rot)
        animation.duration = 1
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        addAnimation(animation, forKey: "circle")
    }
    
    fileprivate func newAngle(_ angle: Float) {
        self.angle = Interman3DModel.normalizeAngle(angle)
        
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

        updateModelScale()
    }
    
    fileprivate func remove() {
        // Remove any link connected to this node
        link_refs.forEach { $0.detach() }
        
        // Stop any current movement
        simdPivot = presentation.simdPivot
        removeAnimation(forKey: "circle")
        
        // Disappear
        let duration = 1.0
        getSubNode().runAction(SCNAction.move(to: SCNVector3(4, 0, 0), duration: duration))
        runAction(SCNAction.sequence([SCNAction.wait(duration: duration), SCNAction.removeFromParentNode()]))
    }
}

class B3DHost : B3D {
    private var host: Node
    private var text_node, text2_node, text3_node: SCNNode?
    private var text_string, text2_string, text3_string: String?
    
    func getHost() -> Node {
        return host
    }

    static func getFromNode(_ node: SCNNode) -> B3DHost? {
        if node.isKind(of: B3DHost.self) { return node as? B3DHost }
        return node.parent != nil ? getFromNode(node.parent!) : nil
    }

    private func createSCNTextNode(_ text: String, size: CGFloat = 1, shift: Float = 0) -> SCNNode {
        let text = SCNText(string: text, extrusionDepth: 0)
        text.flatness = 0
        text.font = UIFont(name: "Helvetica", size: size)
        text.firstMaterial!.diffuse.contents = COLORS.standard_background
        text.firstMaterial!.isDoubleSided = true
        let text_node = SCNNode(geometry: text)
        let (min, max) = text_node.boundingBox
        text_node.pivot = SCNMatrix4MakeTranslation(-1, min.y + (max.y - min.y) / 2 + shift, 0)
        text_node.simdRotation = SIMD4(1, 0, 0, -.pi / 2)
        return text_node
    }

    func updateText(_ counter: Int) {
        let new_text = Self.getDisplayTextFromIndex(text_array: computeDisplayText1stLine(), group_index: counter)
        if new_text != text_string {
            // First line fade out
            let fade_out_action = SCNAction.fadeOut(duration: 0.5)
            let remove = SCNAction.run { $0.removeFromParentNode() }
            let sequence = SCNAction.sequence([fade_out_action, remove])
            text_node!.runAction(sequence)
            
            // First line fade in
            text_string = new_text
            text_node = createSCNTextNode(text_string!)
            text_node!.opacity = 0
            let fade_in_action = SCNAction.fadeIn(duration: 0.5)
            let wait_action = SCNAction.wait(duration: 0.5)
            let sequence_bis = SCNAction.sequence([wait_action, fade_in_action])
            text_node!.runAction(sequence_bis)
            addSubChildNode(text_node!)
        }

        // 2nd line fade out
        let fade_out_action_2 = SCNAction.fadeOut(duration: 0.5)
        let timeshift_action_2 = SCNAction.wait(duration: 0.5)
        let remove_2 = SCNAction.run { $0.removeFromParentNode() }
        let sequence_2 = SCNAction.sequence([timeshift_action_2, fade_out_action_2, remove_2])
        text2_node!.runAction(sequence_2)

        // 2nd line fade in
        let (min, max) = text_node!.boundingBox
        text2_node = createSCNTextNode("tata\(counter)", size: 0.6, shift: (max.y - min.y) / 2 + 0.3)
        text2_node!.opacity = 0
        let timeshift_action_bis_2 = SCNAction.wait(duration: 0.5)
        let fade_in_action_2 = SCNAction.fadeIn(duration: 0.5)
        let wait_action_2 = SCNAction.wait(duration: 0.5)
        let sequence_bis_2 = SCNAction.sequence([timeshift_action_bis_2, wait_action_2, fade_in_action_2])
        text2_node!.runAction(sequence_bis_2)
        addSubChildNode(text2_node!)

        // 3rd line fade out
        let fade_out_action_3 = SCNAction.fadeOut(duration: 0.5)
        let timeshift_action_3 = SCNAction.wait(duration: 1)
        let remove_3 = SCNAction.run { $0.removeFromParentNode() }
        let sequence_3 = SCNAction.sequence([timeshift_action_3, fade_out_action_3, remove_3])
        text3_node!.runAction(sequence_3)

        // 2nd line fade in
        let (min2, max2) = text2_node!.boundingBox
        text3_node = createSCNTextNode("titi\(counter)", size: 0.6, shift: (max.y - min.y) / 2 + 0.3 + (max2.y - min2.y) / 2 + 0.3)
        text3_node!.opacity = 0
        let timeshift_action_bis_3 = SCNAction.wait(duration: 1)
        let fade_in_action_3 = SCNAction.fadeIn(duration: 0.5)
        let wait_action_3 = SCNAction.wait(duration: 0.5)
        let sequence_bis_3 = SCNAction.sequence([timeshift_action_bis_3, wait_action_3, fade_in_action_3])
        text3_node!.runAction(sequence_bis_3)
        addSubChildNode(text3_node!)
    }

    static let max_display_text_length = 40
    static let display_text_separator = " - "
    private static func getDisplayTextFromIndex(text_array: [String], group_index: Int) -> String {
        if text_array.isEmpty { return "" }
        // From here, all_groups can be filled and it will not be empty
        var all_groups = [[String]]()
        // Find all groups to fill all_groups
        var current_input_string_index = 0
        var current_display_group = [String]()
        // Loop until there is no more input strings
        while current_input_string_index < text_array.count {
            // Consume next input string
            current_display_group.append(text_array[current_input_string_index])
            current_input_string_index += 1
            // Compute current group length
            var current_display_group_len = 0
            current_display_group.forEach { text in
                current_display_group_len += text.count
            }
            current_display_group_len += current_display_group.count > 1 ? Self.display_text_separator.count * (current_display_group.count - 1) : 0
            // Check if the group is larger that the max authorized length
            if current_display_group_len > Self.max_display_text_length {
                // Truncate the group if it is possible (it must not become empty)
                if current_display_group.count > 1 {
                    current_display_group.removeLast()
                    current_input_string_index -= 1
                }
                // From here, the current group is full, so save the new group
                all_groups.append(current_display_group)
                // Prepare the next loop for the next group
                current_display_group.removeAll()
            }
        }
        // If the last current group is not empty, save it as a new group
        if current_display_group.isEmpty == false {
            all_groups.append(current_display_group)
        }
        // Note that all_groups.count can not be null, in such a case the function would have returned at the beginning
        let returned_group = all_groups[group_index % all_groups.count]
        var returned_text = ""
        for idx in 0..<returned_group.count {
            returned_text.append(returned_group[idx])
            if idx != returned_group.count - 1 {
                returned_text.append(Self.display_text_separator)
            }
        }
        return returned_text
    }

    private func computeDisplayText1stLine() -> [String] {
        var text_array = [String]()
        text_array.append(contentsOf: host.getDnsNames().map { $0.toString().dropLastDot() }.sorted())
        text_array.append(contentsOf: host.getNames().map { $0.dropLastDot() }.sorted())
        text_array.append(contentsOf: host.getMcastDnsNames().map { $0.toString().dropLastDot() }.sorted())
        if text_array.isEmpty {
            if let foo = host.getV4Addresses().first?.toNumericString() {
                text_array.append(foo)
            } else if let foo = host.getV6Addresses().first?.toNumericString() {
                text_array.append(foo)
            } else {
                text_array.append("no information")
            }
        }
        return text_array
    }
    
    init(_ scn_node: SCNNode, _ host: Node) {
        self.host = host
        super.init(scn_node)

        // First line of text
        var display_text = "no name"
        if let foo = host.getDnsNames().first {
            display_text = foo.toString()
        } else if let foo = host.getNames().first {
            display_text = foo
        } else if let foo = host.getMcastDnsNames().first {
            display_text = foo.toString()
        } else if let foo = host.getV4Addresses().first, let bar = foo.toNumericString() {
            display_text = bar
        } else if let foo = host.getV6Addresses().first, let bar = foo.toNumericString() {
            display_text = bar
        }
        text_string = display_text.dropLastDot()
        text_node = createSCNTextNode(text_string!, size: 1, shift: 0)
        addSubChildNode(text_node!)
        let (min, max) = text_node!.boundingBox
        
        // Second line of text
        let display_text2 = "this is the 2nd line of text with many informations"
        text2_string = display_text2
        text2_node = createSCNTextNode(text2_string!, size: 0.6, shift: (max.y - min.y) / 2 + 0.3)
        addSubChildNode(text2_node!)
        let (min2, max2) = text2_node!.boundingBox

        // Third line of text
        let display_text3 = "this is the third line of text with many informations"
        text3_string = display_text3
        text3_node = createSCNTextNode(text3_string!, size: 0.6, shift: (max.y - min.y) / 2 + 0.3 + (max2.y - min2.y) / 2 + 0.3)
        addSubChildNode(text3_node!)
    }

    // The associated Node has been updated, we may need to update the displayed values and the 3D model
    func updateModelAndValues() {
        // /////////////////////////////////
        // Update text content

        
        
        // /////////////////////////////////
        // Update 3D model
        
        if host.isLocalHost() {
            if UIDevice.current.userInterfaceIdiom == .pad {
                updateModel(ComponentTemplates.iPad)
            } else {
                updateModel(ComponentTemplates.iPhone)
            }
            return
        }

        if host.getMcastDnsNames().contains(FQDN("flood", "eowyn.eu.org")) {
            updateModel(ComponentTemplates.ovh)
            return
        }

        if host.toSectionTypes().contains(.gateway) {
            updateModel(ComponentTemplates.router)
            return
        }

        if host.toSectionTypes().contains(.internet) {
            updateModel(ComponentTemplates.server)
            return
        }

        // https://openairplay.github.io/airplay-spec/service_discovery.html
        if let airplay = (host.getServices().filter { $0.name == "_airplay._tcp." }).first {
            if let model = airplay.attr["model"] {
                if model.starts(with: "Macmini") {
                    updateModel(ComponentTemplates.macmini)
                    return
                }
                if model.starts(with: "AppleTV") {
                    updateModel(ComponentTemplates.atv)
                    return
                }
                if model.starts(with: "AudioAccessory") {
                    updateModel(ComponentTemplates.homepod)
                    return
                }
            }
        }

        if let googlecast = (host.getServices().filter { $0.name == "_googlecast._tcp." }).first {
            if let model = googlecast.attr["md"] {
                if model.starts(with: "Chromecast") {
                    updateModel(ComponentTemplates.chromecast)
                    return
                }

                if model.starts(with: "Google Home") {
                    updateModel(ComponentTemplates.googlehome)
                    return
                }
            }
        }

        if (host.getServices().filter { $0.name == "_raop._tcp." }).isEmpty == false {
            updateModel(ComponentTemplates.speaker)
            return
        }

        if (host.getServices().filter { $0.name == "_pdl-datastream._tcp." || $0.name == "_scanner._tcp." }).isEmpty == false {
            updateModel(ComponentTemplates.printer)
            return
        }

        if (host.getServices().filter { $0.name == "_apple-mobdev2._tcp." }).isEmpty == false {
            updateModel(ComponentTemplates.iPhone)
            return
        }

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Broadcast3D : SCNNode {
    private var broadcast_node_draw: SCNNode
    private var torus: SCNTorus

    override init() {
        broadcast_node_draw = SCNNode()
        torus = SCNTorus(ringRadius: 0.1, pipeRadius: 0.01)
        torus.firstMaterial!.diffuse.contents = UIColor(red: 255.0/255.0, green: 108.0/255.0, blue: 91.0/255.0, alpha: 1)
        broadcast_node_draw.geometry = torus
        super.init()
        addChildNode(broadcast_node_draw)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func firstAnim() {
        torus.ringRadius = 0.1
        let animation = CABasicAnimation(keyPath: "geometry.ringRadius")
        animation.repeatCount = .infinity
        animation.fromValue = 0.1
        animation.toValue = 1
        animation.duration = 0.5
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        broadcast_node_draw.addAnimation(animation, forKey: "broadcast")
    }
    
    fileprivate func removeAnim() {
        broadcast_node_draw.removeAllAnimations()
    }
}

// 3D link types:
// - scan TCP ports
// - port discovered
// - multicast Bonjour service discovered
class Link3D : SCNNode {
    fileprivate weak var from_b3d: B3D?, to_b3d: B3D?
    private let link_node_draw: SCNNode
    
    fileprivate var color: UIColor { UIColor(red: 255.0/255.0, green: 108.0/255.0, blue: 91.0/255.0, alpha: 1) }
 //   fileprivate var height: Float { 0 }
    fileprivate var height: Float { -2 * B3D.default_scale }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getEnds() -> Set<B3D> {
        var ends = Set<B3D>()
        if from_b3d != nil { ends.insert(from_b3d!) }
        if to_b3d != nil { ends.insert(to_b3d!) }
        return ends
    }
    
    init(_ from_b3d: B3D, _ to_b3d: B3D) {
        link_node_draw = SCNNode()
        super.init()

        self.from_b3d = from_b3d
        self.to_b3d = to_b3d
        from_b3d.addLinkRef(self)
        to_b3d.addLinkRef(self)

        addChildNode(link_node_draw)
        link_node_draw.geometry = SCNCylinder(radius: 0.03, height: 1)
        link_node_draw.geometry!.firstMaterial!.diffuse.contents = color

        let look_at_contraint = SCNLookAtConstraint(target: to_b3d.getSubNode())
        look_at_contraint.influenceFactor = 1
        look_at_contraint.isGimbalLockEnabled = false
        constraints = [look_at_contraint]

        let size_constraint = SCNTransformConstraint(inWorldSpace: false) { node, transform in
            let distance = simd_distance(simd_float3(self.presentation.worldPosition), simd_float3(to_b3d.presentation.worldPosition))
            var transf = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
            transf = SCNMatrix4Mult(SCNMatrix4MakeScale(1, distance / B3D.default_scale, 1), transf)
            transf = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, -0.5, -self.height), transf)
            return transf
        }
        size_constraint.influenceFactor = 1
        link_node_draw.constraints = [size_constraint]
        
        startBlinking()
        
        from_b3d.addSubChildNode(self)
    }

    private func startBlinking() {
        let foo = link_node_draw.geometry!.firstMaterial!
        let animation = CABasicAnimation(keyPath: "transparency")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 0.5
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        foo.addAnimation(animation, forKey: "blink")

    }
    
    // Ask the object to remove itself, either because one of the connected node will be removed soon, or because the link is not needed anymore
    fileprivate func detach() {
        if let from_b3d { from_b3d.removeLinkRef(self) }
        if let to_b3d { to_b3d.removeLinkRef(self) }
        removeFromParentNode()
    }
}

class Link3DScanNode : Link3D {
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(_ from_b3d: B3D, _ to_b3d: B3D) {
        super.init(from_b3d, to_b3d)
    }
}

class Link3DPortDiscovered : Link3D {
    private let port: UInt16

    override fileprivate var color: UIColor { UIColor(red: 0, green: 108.0/255.0, blue: 91.0/255.0, alpha: 1) }
    override fileprivate var height: Float { -B3D.default_scale }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(_ from_b3d: B3D, _ to_b3d: B3D, _ port: UInt16) {
        self.port = port
        super.init(from_b3d, to_b3d)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.detach()
        }
    }
}

public class Interman3DModel : ObservableObject {
    static let shared = Interman3DModel()

    public var scene: SCNScene?
    private var b3d_hosts: [B3DHost]
    private var broadcasts = Set<Broadcast3D>()

    // Does not contain localhost IPs
    private var scanned_IPs = Set<IPAddress>()
    
    private var scheduled_text_update_counter = 0

    public init() {
        b3d_hosts = [B3DHost]()
        Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: true) { _ in
            self.scheduledOperations()
        }
    }

    func getNHosts() -> Int {
        return b3d_hosts.count
    }

    // Return the node that is just highest than the middle right position on the screen
    func getLowestNodeAngle(_ angle: Float) -> B3DHost {
        return b3d_hosts.map { (Interman3DModel.normalizeAngle($0.getAngle() + angle), $0) }.sorted { $0.0 < $1.0 }.last!.1
    }
    
    private static func renewLink3DScanNode(link: Link3DScanNode) {
        guard let from_b3d = link.from_b3d, let to_b3d = link.to_b3d else { return }
        link.detach()
        _ = Link3DScanNode(from_b3d, to_b3d)
    }

    // Needed due to a bug in SCeneKit: when things happen on the 3D model, while the 3D view is not displayed, you some time encounter bad things. Here, we recreate some nodes since they do not appear in certain circonstances. Here is a way to reproduce the bug :
    // start app, got to Exploration tab, click reload, click stop, select a node that is not localhost, click to scan TCP ports on the node, go to the 3D tab. The 3D link scan node does not appear.
    private func scheduledOperations() {
        var links = Set<Link3DScanNode>()
        b3d_hosts.forEach { links.formUnion($0.getLink3DScanNodes()) }
        links.forEach { Self.renewLink3DScanNode(link: $0) }
    }

    func scheduledTextUpdate() {
        scheduled_text_update_counter += 1
        b3d_hosts.forEach { b3d in
            b3d.updateText(scheduled_text_update_counter)
        }
    }

    static func normalizeAngle(_ angle: Float) -> Float {
        var new_angle = angle.truncatingRemainder(dividingBy: 2 * .pi)
        if new_angle < 0 { new_angle += 2 * .pi }
        return new_angle
    }
    
    private func updateAngles() {
        let node_count = b3d_hosts.count
        for i in 0..<node_count {
            let angle = Interman3DModel.normalizeAngle(Float(i) * 2 * .pi / Float(node_count))
            b3d_hosts[i].newAngle(angle)
        }
    }
    
    func getB3DHost(_ host: Node) -> B3DHost? {
        // Should be faster with an associative map
        guard let b3d_host = (b3d_hosts.filter { $0.getHost().isSimilar(with: host) }).first else {
            return nil
        }
        return b3d_host
    }
    
    // We could implement a cache, but it is not sure it may really improve global performances
    private func getB3DLocalHost() -> B3DHost? {
        guard let local_host = DBMaster.shared.sections[.localhost]?.nodes.first else {
            print("\(#function): warning, localhost not found")
            return nil
        }

        guard let local_node = getB3DHost(local_host) else {
            print("\(#function): warning, localhost is not backed by a 3D node")
            return nil
        }

        return local_node
    }

    private func detachB3DSimilarHost(_ host: Node) -> B3DHost? {
        guard let b3d_host = (b3d_hosts.filter { $0.getHost().isSimilar(with: host) }).first else {
            return nil
        }
        b3d_hosts.removeAll { $0 == b3d_host }
        return b3d_host
    }

    private func detachB3DHostInstance(_ host: Node) -> B3DHost? {
        guard let b3d_host = (b3d_hosts.filter { $0.getHost() === host }).first else {
            return nil
        }
        b3d_hosts.removeAll { $0 == b3d_host }
        return b3d_host
    }

    // Sync with the main model
    func notifyNodeAdded(_ node: Node) {
        addHost(node)
    }

    // Sync with the main model
    func notifyNodeRemoved(_ host: Node) {
        guard let b3d_host = detachB3DSimilarHost(host) else { return }
        updateAngles()
        b3d_host.remove()
    }

    // Sync with the main model
    func notifyNodeMerged(_ node: Node, _ into: Node) {
        // print("\(#function)")
        guard let b3d_host = detachB3DHostInstance(into) else { return }
        updateAngles()
        b3d_host.remove()
    }

    // Sync with the main model
    func notifyNodeUpdated(_ node: Node) {
        // print("\(#function)")
        // Update the displayed values and the 3D model
        guard let b3d_host = getB3DHost(node) else { return }
        b3d_host.updateModelAndValues()
    }

    func notifyScanNode(_ node: Node, _ address: IPAddress) {
        guard let local_node = getB3DLocalHost() else {
            print("\(#function): Warning: localhost is not backed by a 3D node")
            return
        }
        
        guard let target = getB3DHost(node) else {
            print("\(#function): warning, scan target is not backed by a 3D node")
            return
        }

        if local_node != target {
            scanned_IPs.insert(address)
            // print("add new scanned IP: \(scanned_IPs)")
            _ = Link3DScanNode(local_node, target)
        }
    }

    func notifyScanNodeFinished(_ node: Node, _ address: IPAddress) {
        guard let local_node = getB3DLocalHost() else {
            print("\(#function): Warning: localhost is not backed by a 3D node")
            return
        }
        
        guard let target = getB3DHost(node) else {
            print("\(#function): warning, scan target is not backed by a 3D node")
            return
        }

        scanned_IPs.remove(address)
        // print("remove scanned IP: \(scanned_IPs)")
        target.getLinks(with: local_node).forEach { $0.detach() }
    }

    func notifyPortDiscovered(_ node: Node, _ port: UInt16) {
        guard let local_node = getB3DLocalHost() else {
            print("\(#function): Warning: localhost is not backed by a 3D node")
            return
        }
        
        guard let target = getB3DHost(node) else {
            print("\(#function): warning, scan target is not backed by a 3D node")
            return
        }

        if local_node != target {
            _ = Link3DPortDiscovered(local_node, target, port)
        }
    }
    
    func notifyBroadcast() {
        addBroadcast()
    }

    func notifyBroadcastFinished() {
        broadcasts.forEach {
            $0.removeAnim()
            $0.removeFromParentNode()
        }
        broadcasts.removeAll()
    }

    private func addBroadcast() {
        let broadcast = Broadcast3D()
        broadcasts.insert(broadcast)
        broadcast.firstAnim()
        scene?.rootNode.addChildNode(broadcast)
    }
    
    private func addHost(_ host: Node) {
        let b3d_host = B3DHost(ComponentTemplates.laptop2, host)
        b3d_host.updateModelAndValues()
        b3d_hosts.append(b3d_host)
        let node_count = b3d_hosts.count
        let angle = Interman3DModel.normalizeAngle(-2 * .pi / Float(node_count))
        b3d_host.firstAnim(angle)
        scene?.rootNode.addChildNode(b3d_host)
        // Set to add axes to debug 3D orientation of the scene
        // b3d_host.addChildNode(ComponentTemplates.createAxes(0.2))
        updateAngles()
    }
    
    private static var debug_cnt = 0
    func testIHMCreate() {
        // IHM "create"

        if Interman3DModel.debug_cnt == 0 {
            let node = Node()
            node.addMcastFQDN(FQDN("dns8", "quad8.net"))
            _ = DBMaster.shared.addNode(node)
            Interman3DModel.debug_cnt += 1
        } else {
            let node = Node()
            node.addMcastFQDN(FQDN("dns8", "quad8.net"))
            node.addMcastFQDN(FQDN("dns9", "quad9.net"))
            _ = DBMaster.shared.addNode(node)
            print("OK")
        }
    }
    
    func testIHMUpdate() {
        // IHM "update"
        print(#function)

        addBroadcast()
        
        return
        
        guard let _first_host = DBMaster.getNode(address: IPv4Address("192.168.1.254")!) else {
            print("\(#function): warning, router not found")
            return
        }
        guard let _b3d_first_host = getB3DHost(_first_host) else {
            print("\(#function): warning, router is not backed by a 3D node")
            return
        }

        guard let link3d_scan_node = _b3d_first_host.getLinks().first as? Link3DScanNode else {
            print("bad link")
            return
        }
        
        print("link3D address: \(Unmanaged.passUnretained(link3d_scan_node).toOpaque())")
        print(link3d_scan_node.presentation.worldPosition)
        
        
        
        
        guard let from_b3d = link3d_scan_node.from_b3d, let to_b3d = link3d_scan_node.to_b3d else {
            return
        }
        link3d_scan_node.detach()
        let bar = Link3DScanNode(from_b3d, to_b3d)
        print(bar.presentation.worldPosition)
        
        
        return
        
        /*
        guard let first_host = DBMaster.shared.sections[.localhost]?.nodes.first else {
            print("\(#function): warning, localhost not found")
            return
        }*/

        guard let first_host = DBMaster.getNode(mcast_fqdn: FQDN("dns8", "quad8.net")) else {
            print("\(#function): warning, dns8 not found")
            return
        }

        guard let second_host = DBMaster.getNode(mcast_fqdn: FQDN("flood", "eowyn.eu.org")) else {
            print("\(#function): warning, flood not found")
            return
        }

        guard let b3d_first_host = getB3DHost(first_host) else {
            print("\(#function): warning, dns8 is not backed by a 3D node")
            return
        }
        
        guard let b3d_second_host = getB3DHost(second_host) else {
            print("\(#function): warning, flood is not backed by a 3D node")
            return
        }

//        b3d_first_host.addLink(b3d_second_host)
//        b3d_second_host.addLink(b3d_first_host)
        let foo = Link3DScanNode(b3d_second_host, b3d_first_host)

        /*
        if let host = DBMaster.getNode(mcast_fqdn: FQDN("dns", "google")) {
            print("XXXXX: host dns.google found")
            if let b3d_host = getB3DHost(host) {
                print("XXXXX: B3DHost dns.google found")
//                b3d_host.newAngle(.pi / 4)
                notifyNodeRemoved(host)
//                updateAngles()
            }
        }
 */

        /*
        // translation
//        var x: simd_float4x4 = matrix_identity_float4x4
//        x[3, 0] = -1
//        x[3, 2] = -1

        // rotations :
        // avec quaternions : https://stackoverflow.com/questions/49601997/is-there-a-metal-library-function-to-create-a-simd-rotation-matrix
        // avec GL : https://developer.apple.com/documentation/glkit/1488683-glkmatrix4makezrotation
        let piv0 = simd_float4x4(simd_quatf(angle: GLKMathDegreesToRadians(10), axis: SIMD3(0, 1, 0)))
        // rad, x, y, z
        let piv1 = simd_float4x4(matrix: GLKMatrix4MakeRotation(GLKMathDegreesToRadians(10), 0, 1, 0))
        b3d_test?.simdPivot = piv1
*/
        
        print("testComponent() done")
    }
}
