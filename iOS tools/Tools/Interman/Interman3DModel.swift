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
// PI : M_2_PI, Float.pi

extension simd_float4x4 {
    public init(matrix: GLKMatrix4) {
        self.init(columns: (SIMD4<Float>(x: matrix.m00, y: matrix.m01, z: matrix.m02, w: matrix.m03),
                            SIMD4<Float>(x: matrix.m10, y: matrix.m11, z: matrix.m12, w: matrix.m13),
                            SIMD4<Float>(x: matrix.m20, y: matrix.m21, z: matrix.m22, w: matrix.m23),
                            SIMD4<Float>(x: matrix.m30, y: matrix.m31, z: matrix.m32, w: matrix.m33)))
    }
}

class B3D : SCNNode {
    public init(_ scn_node: SCNNode) {
        super.init()
        let _node = scn_node.clone()
        addChildNode(_node.clone())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class B3DNode : B3D {
    private /* weak */ var node: Node?
    
    public init(_ scn_node: SCNNode, _ node: Node) {
        super.init(scn_node)
        self.node = node
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ComponentTemplates {
    public static let standard = SCNScene(named: "Interman 3D Standard Component.scn")!.rootNode
}

public class Interman3DModel : ObservableObject {
    static let shared = Interman3DModel()
    public var scene: SCNScene?

    private var b3d_nodes: [B3DNode]
    
    private var b3d_test: B3D?

    public init() {
        print("MANAGER INIT")
        b3d_nodes = [B3DNode]()
    }
    
    internal func addComponent(_ node: Node) {
        let factor: Float = 10

        print(#function)
        let b3d_node = B3DNode(ComponentTemplates.standard, node)

        let node_count = b3d_nodes.count
        let rot = simd_float4x4(simd_quatf(angle: GLKMathDegreesToRadians(9.5) * Float(node_count), axis: SIMD3(0, 1, 0)))
        
        var transl = matrix_identity_float4x4
        transl[3, 0] = -factor
        transl[3, 2] = -factor

        b3d_node.simdScale = simd_float3(1/factor, 1/factor, 1/factor)

        let animation = CABasicAnimation(keyPath: "pivot")
        animation.fromValue = SCNMatrix4(transl)
        animation.toValue = SCNMatrix4(transl * rot)
        animation.duration = 10.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        b3d_node.addAnimation(animation, forKey: nil)

        let text = SCNText(string: node.dns_names.first?.toString(), extrusionDepth: 0)
        text.flatness = 0.01
        text.firstMaterial!.diffuse.contents = UIColor.yellow

        let text_node = SCNNode(geometry: text)
        text_node.simdScale = SIMD3(0.1, 0.1, 0.1)
        text_node.simdRotation = SIMD4(1, 0, 0, -Float(M_2_PI))
        b3d_node.addChildNode(text_node)

        scene?.rootNode.addChildNode(b3d_node)
        b3d_nodes.append(b3d_node)

        print("addComponent(node) done")

    }
    
    internal func addComponent() {
        print(#function)
        let b3d = B3D(ComponentTemplates.standard)
        print("b3d=\(b3d)")

        b3d_test = b3d
        scene?.rootNode.addChildNode(b3d)
        print("addComponent() done")
    }
    
    // internal
    public func testComponent() {
        print(#function)

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

        print("testComponent() done")
    }
}
