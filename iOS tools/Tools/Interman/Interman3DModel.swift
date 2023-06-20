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

struct ComponentTemplates {
    public static let standard = SCNScene(named: "Interman 3D Standard Component.scn")!.rootNode
    public static let axes = SCNScene(named: "Repère.scn")!.rootNode
    
    public static func createAxes(_ scale: Float) -> SCNNode {
        let new_axes = axes.clone()
        new_axes.scale = SCNVector3(scale, scale, scale)
        return new_axes
    }
}

extension simd_float4x4 {
    public init(matrix: GLKMatrix4) {
        self.init(columns: (SIMD4<Float>(x: matrix.m00, y: matrix.m01, z: matrix.m02, w: matrix.m03),
                            SIMD4<Float>(x: matrix.m10, y: matrix.m11, z: matrix.m12, w: matrix.m13),
                            SIMD4<Float>(x: matrix.m20, y: matrix.m21, z: matrix.m22, w: matrix.m23),
                            SIMD4<Float>(x: matrix.m30, y: matrix.m31, z: matrix.m32, w: matrix.m33)))
    }
}

class B3D : SCNNode {
    static let default_scale: Float = 0.1
    private let sub_node: SCNNode
    private var angle: Float = 0
    
    public init(_ scn_node: SCNNode) {
        sub_node = scn_node.clone()
        sub_node.simdScale = simd_float3(B3D.default_scale, B3D.default_scale, B3D.default_scale)
        super.init()
        addChildNode(sub_node)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addSubChildNode(_ child: SCNNode) {
        sub_node.addChildNode(child)
    }
    
    fileprivate func getSubNode() -> SCNNode {
        return sub_node
    }
    
    func getAngle() -> Float {
        return angle
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
    }
    
    fileprivate func remove() {
        // Stop any current movement
        simdPivot = presentation.simdPivot
        removeAnimation(forKey: "circle")
        
        // Disappear
        let duration = 1.0
        getSubNode().runAction(SCNAction.move(to: SCNVector3(4, 0, 0), duration: duration))
        runAction(SCNAction.sequence([SCNAction.wait(duration: duration), SCNAction.removeFromParentNode()]))
    }

    fileprivate func addLink(_ to_node: B3D) {
        let link_node = SCNNode()
        let link_node_draw = SCNNode()
        link_node.addChildNode(link_node_draw)
        link_node_draw.geometry = SCNCylinder(radius: 0.1, height: 1)
        link_node_draw.geometry!.firstMaterial!.diffuse.contents = UIColor(red: 255.0/255.0, green: 108.0/255.0, blue: 91.0/255.0, alpha: 1)

        let look_at_contraint = SCNLookAtConstraint(target: to_node.sub_node)
        look_at_contraint.influenceFactor = 1
        look_at_contraint.isGimbalLockEnabled = false
        link_node.constraints = [look_at_contraint]

        let size_constraint = SCNTransformConstraint(inWorldSpace: false) { node, transform in
            let distance = simd_distance(simd_float3(self.presentation.worldPosition), simd_float3(to_node.presentation.worldPosition))
            var transf = SCNMatrix4MakeRotation(.pi / 2, 1, 0, 0)
            transf = SCNMatrix4Mult(SCNMatrix4MakeScale(1, distance / B3D.default_scale, 1), transf)
            transf = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, -0.5, 0), transf)
            return transf
        }
        size_constraint.influenceFactor = 1
        link_node_draw.constraints = [size_constraint]
        
        addSubChildNode(link_node)
    }
}

class B3DHost : B3D {
    private var host: Node

    func getHost() -> Node {
        return host
    }

    static func getFromNode(_ node: SCNNode) -> B3DHost? {
        if node.isKind(of: B3DHost.self) { return node as? B3DHost }
        return node.parent != nil ? getFromNode(node.parent!) : nil
    }
    
    init(_ scn_node: SCNNode, _ host: Node) {
        self.host = host
        super.init(scn_node)

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
        let text = SCNText(string: display_text, extrusionDepth: 0)
        text.flatness = 0.001
        text.firstMaterial!.diffuse.contents = UIColor.yellow
        let text_node = SCNNode(geometry: text)
        text.font = UIFont(name: "Helvetica", size: 1)
        text_node.simdRotation = SIMD4(1, 0, 0, -.pi / 2)
        addSubChildNode(text_node)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class Interman3DModel : ObservableObject {
    static let shared = Interman3DModel()

    public var scene: SCNScene?
    private var b3d_hosts: [B3DHost]
    
    public init() {
        print("MANAGER INIT")
        b3d_hosts = [B3DHost]()
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
        print("\(#function)")
        
        guard let b3d_host = detachB3DSimilarHost(host) else { return }
        updateAngles()
        b3d_host.remove()
    }

    // Sync with the main model
    func notifyNodeMerged(_ node: Node, _ into: Node) {
        print("\(#function)")
        guard let b3d_host = detachB3DHostInstance(into) else { return }
        updateAngles()
        b3d_host.remove()
    }

    // Sync with the main model
    func notifyNodeUpdated(_ node: Node) {
        print("\(#function)")

    }

    private func addHost(_ host: Node) {
        let b3d_host = B3DHost(ComponentTemplates.standard, host)
        b3d_hosts.append(b3d_host)
        let node_count = b3d_hosts.count
        let angle = Interman3DModel.normalizeAngle(-2 * .pi / Float(node_count))
        b3d_host.firstAnim(angle)
        scene?.rootNode.addChildNode(b3d_host)
        // DEBUG - A REMETTRE
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

        /*
        guard let first_host = DBMaster.shared.sections[.localhost]?.nodes.first else {
            print("\(#function): warning, localhost not found")
            return
        }*/

        guard let first_host = DBMaster.getNode(mcast_fqdn: FQDN("dns", "google")) else {
            print("\(#function): warning, dns not found")
            return
        }

        guard let second_host = DBMaster.getNode(mcast_fqdn: FQDN("flood", "eowyn.eu.org")) else {
            print("\(#function): warning, flood not found")
            return
        }

        guard let b3d_first_host = getB3DHost(first_host) else {
            print("\(#function): warning, dns is not backed by a 3D node")
            return
        }
        
        guard let b3d_second_host = getB3DHost(second_host) else {
            print("\(#function): warning, flood is not backed by a 3D node")
            return
        }

        b3d_first_host.addLink(b3d_second_host)
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
