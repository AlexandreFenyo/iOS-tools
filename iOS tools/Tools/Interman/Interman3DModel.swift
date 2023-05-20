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

// SIMDx et SCNVectorx :
// text_node.simdScale = SIMD3(0.1, 0.1, 0.1)
// text_node.scale = SCNVector3(0.1, 0.1, 0.1)

// matrices de translation et rotation :
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/CoreAnimationBasics/CoreAnimationBasics.html#//apple_ref/doc/uid/TP40004514-CH2-SW3

 // créer des matrices : doc de SCNMatrix4

struct ComponentTemplates {
    public static let standard = SCNScene(named: "Interman 3D Standard Component.scn")!.rootNode
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
    private let sub_node: SCNNode
    private var angle: Float = 0
    
    public init(_ scn_node: SCNNode) {
        sub_node = scn_node.clone()
        sub_node.simdScale = simd_float3(0.1, 0.1, 0.1)
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

    fileprivate func getAngle() -> Float {
        return angle
    }
    
    fileprivate func firstAnim(_ angle: Float) {
        self.angle = angle

        let rot = simd_float4x4(simd_quatf(angle: angle, axis: SIMD3(0, 1, 0)))
        var transl = matrix_identity_float4x4
        transl[3, 0] = -1
        simdPivot = transl * rot
        let animation = CABasicAnimation(keyPath: "pivot")
        animation.fromValue = SCNMatrix4(rot)
        animation.toValue = SCNMatrix4(transl * rot)
        animation.duration = 5.0
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        addAnimation(animation, forKey: "circle")
    }
    
    fileprivate func newAngle(_ angle: Float) {
        self.angle = angle

        pivot = presentation.pivot
        removeAnimation(forKey: "circle")

        let rot = simd_float4x4(simd_quatf(angle: angle, axis: SIMD3(0, 1, 0)))
        var transl = matrix_identity_float4x4
        transl[3, 0] = -1
        let animation = CABasicAnimation(keyPath: "pivot")
        animation.toValue = SCNMatrix4(transl * rot)
        animation.duration = 5.0
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        addAnimation(animation, forKey: "circle")
    }
}

class B3DHost : B3D {
    private var host: Node

    fileprivate func getHost() -> Node {
        return host
    }
    
    public init(_ scn_node: SCNNode, _ host: Node) {
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

    private func updateAngles() {
        let node_count = b3d_hosts.count
        for i in 0..<node_count {
            let angle = Float(i) * 2 * .pi / Float(node_count)
            b3d_hosts[i].newAngle(angle)
        }
    }
    
    private func getB3DHost(_ host: Node) -> B3DHost? {
        // Should be faster with an associative map
        guard let b3d_host = (b3d_hosts.filter { $0.getHost().isSimilar(with: host) }).first else {
            return nil
        }
        return b3d_host
    }

    private func detachB3DHost(_ host: Node) -> B3DHost? {
        guard let b3d_host = (b3d_hosts.filter { $0.getHost().isSimilar(with: host) }).first else {
            return nil
        }
        b3d_hosts.removeAll { $0 == b3d_host }
        return b3d_host
    }

    // Sync with the main model
    public func notifyNodeAdded(_ node: Node) {
        print("\(#function): \(node.fullDump())")
        addHost(node)
    }

    // Sync with the main model
    public func notifyNodeRemoved(_ host: Node) {
        print("\(#function)")
        
        guard let b3d_host = detachB3DHost(host) else { return }
        updateAngles()
        
        b3d_host.simdPivot = b3d_host.presentation.simdPivot
        b3d_host.removeAnimation(forKey: "circle")
        let animation = CABasicAnimation(keyPath: "position")
        animation.toValue = SCNVector3(1, 0, 0)
        animation.duration = 5.0
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        b3d_host.getSubNode().addAnimation(animation, forKey: "remove")
        
        return

        /*
        let rot = simd_float4x4(simd_quatf(angle: b3d_host.getAngle(), axis: SIMD3(0, 1, 0)))
        var transl = matrix_identity_float4x4
        transl[3, 0] = 0
        transl[3, 2] = 0

        let animation = CABasicAnimation(keyPath: "pivot")
//        animation.fromValue = SCNMatrix4(transl)
        animation.toValue = SCNMatrix4(rot)
        animation.duration = 15.0
        b3d_host.addAnimation(animation, forKey: "circle")
*/
        
/*
        let rot = simd_float4x4(simd_quatf(angle: GLKMathDegreesToRadians(45), axis: SIMD3(0, 1, 0)))
        var transl = matrix_identity_float4x4
        transl[3, 0] = -factor / 5
        transl[3, 2] = -factor / 5
        b3d_node.simdPivot = transl * rot
  */

        /*
        let rot = simd_float4x4(simd_quatf(angle: GLKMathDegreesToRadians(9.5) * Float(node_count), axis: SIMD3(0, 1, 0)))
        var transl = matrix_identity_float4x4
        transl[3, 0] = -factor
        transl[3, 2] = -factor
        b3d_node.simdScale = simd_float3(1/factor, 1/factor, 1/factor)
        // Set final state
        b3d_node.simdPivot = transl * rot
        let animation = CABasicAnimation(keyPath: "pivot")
        animation.fromValue = SCNMatrix4(transl)
        animation.toValue = SCNMatrix4(transl * rot)
        animation.duration = 15.0
        b3d_node.addAnimation(animation, forKey: "circle")
*/

        return
        /*
        let animation = CABasicAnimation(keyPath: "pivot")
//        animation.fromValue = SCNMatrix4(transl)
        animation.toValue = SCNMatrix4(matrix_identity_float4x4)
        animation.duration = 15.0
        b3d_node.addAnimation(animation, forKey: "center")
*/
    }

    // Sync with the main model
    public func notifyNodeMerged(_ node: Node, _ into: Node) {
        print("\(#function)")

    }

    // Sync with the main model
    public func notifyNodeUpdated(_ node: Node) {
        print("\(#function)")

    }

    public func addHost(_ host: Node) {
        print(#function)

        let b3d_host = B3DHost(ComponentTemplates.standard, host)
        b3d_hosts.append(b3d_host)
        let node_count = b3d_hosts.count
        let angle = -2 * .pi / Float(node_count)
        b3d_host.firstAnim(angle)
        scene?.rootNode.addChildNode(b3d_host)

        updateAngles()
    }
    
    public func addComponent() {
        // IHM "create"
        print(#function)

        let node = Node()
        node.addName("testing.com")
        DBMaster.shared.addNode(node)

/*
        let b3d = B3D(ComponentTemplates.standard)
        print("b3d=\(b3d)")
        b3d_test = b3d
        scene?.rootNode.addChildNode(b3d)
        print("addComponent() done")
 */
    }
    
    public func testComponent() {
        // IHM "update"
        print(#function)

        // repositionner tous les noeuds
//        updateAngles()
//        return
        
        if let host = DBMaster.getNode(mcast_fqdn: FQDN("dns", "google")) {
            print("XXXXX: host dns.google found")
            if let b3d_host = getB3DHost(host) {
                print("XXXXX: B3DHost dns.google found")
//                b3d_host.newAngle(.pi / 4)
                notifyNodeRemoved(host)
//                updateAngles()
            }
        }
        
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
