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

// B3D: basic 3D node in this app

class B3D : SCNNode {
    public init(_ scn_node: SCNNode) {
        super.init()
        addChildNode(scn_node.clone())
        simdPosition.x = 1
        simdRotation.z = 0.2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class B3DNode : B3D {
    private weak var node: Node?
    
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
        let b3d_node = B3DNode(ComponentTemplates.standard, node)
        b3d_test = b3d_node
        scene?.rootNode.addChildNode(b3d_node)
        print("addComponent(node) done")
    }
    
    internal func addComponent() {
        let b3d = B3D(ComponentTemplates.standard)
        b3d_test = b3d
        scene?.rootNode.addChildNode(b3d)
        print("addComponent() done")
    }
    
    internal func testComponent() {
        b3d_test?.simdRotation.z += 1
//        b3d_test?.simdPosition.x += 0.1
        print("testComponent() done")
    }
}
