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
// avec GL : https://developer.apple.com/documentation/glkit/1488683-glkmatrix4makezrotation
// var piv0 = simd_float4x4(simd_quatf(angle: GLKMathDegreesToRadians(10), axis: SIMD3(0, 1, 0)))
// b3d_test?.simdPivot = piv0
// rad, x, y, z
// var piv1 = simd_float4x4(matrix: GLKMatrix4MakeRotation(GLKMathDegreesToRadians(10), 0, 1, 0))
// b3d_test?.simdPivot = piv1

extension simd_float4x4 {
    public init(matrix: GLKMatrix4) {
        self.init(columns: (SIMD4<Float>(x: matrix.m00, y: matrix.m01, z: matrix.m02, w: matrix.m03),
                            SIMD4<Float>(x: matrix.m10, y: matrix.m11, z: matrix.m12, w: matrix.m13),
                            SIMD4<Float>(x: matrix.m20, y: matrix.m21, z: matrix.m22, w: matrix.m23),
                            SIMD4<Float>(x: matrix.m30, y: matrix.m31, z: matrix.m32, w: matrix.m33)))
    }
}

// B3D: basic 3D node in this app

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

    private var b3d_test: B3D?
    
    public init() {
        print("MANAGER INIT")
    }
    
    internal func addComponent(_ node: Node) {
        print(#function)
        let b3d_node = B3DNode(ComponentTemplates.standard, node)
        print("b3d_node=\(b3d_node)")
        
        b3d_test = b3d_node
        scene?.rootNode.addChildNode(b3d_node)
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
//        print(b3d_test?.pivot)
   //     b3d_test?.simdPosition.x = 1

//        print(b3d_test?.simdPivot)
        
        //        b3d_test?.simdPivot.

//        var x: simd_float4x4 = matrix_identity_float4x4
//        x[3, 0] = -1
//        x[3, 2] = -1

        // rotations :
        // avec quaternions : https://stackoverflow.com/questions/49601997/is-there-a-metal-library-function-to-create-a-simd-rotation-matrix
        // avec GL : https://developer.apple.com/documentation/glkit/1488683-glkmatrix4makezrotation
        var piv0 = simd_float4x4(simd_quatf(angle: GLKMathDegreesToRadians(10), axis: SIMD3(0, 1, 0)))
        // rad, x, y, z
        var piv1 = simd_float4x4(matrix: GLKMatrix4MakeRotation(GLKMathDegreesToRadians(10), 0, 1, 0))
        b3d_test?.simdPivot = piv1

//        print("4x4: \(foo)")
        
//        b3d_test?.simdPivot = x
        
        //      b3d_test?.simdRotation.x += 1
//        b3d_test?.simdRotation.y += 1
  //      b3d_test?.simdRotation.z += 1
//        b3d_test?.simdRotation.w += 0.1
//        print(b3d_test?.pivot)
//        b3d_test?.simdPosition.x += 0.1
        print("testComponent() done")
    }
}
