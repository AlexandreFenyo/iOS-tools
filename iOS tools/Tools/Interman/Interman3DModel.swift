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

// C3D: 3D Component in this app

class C3D : SCNNode {
    public init(_ scn_node: SCNNode) {
        super.init()
        addChildNode(scn_node.clone())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class C3DNode : C3D {
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
    
    public init() {
        print("MANAGER INIT")
    }
    
    internal func addComponent(_ node: Node) {
        scene?.rootNode.addChildNode(C3DNode(ComponentTemplates.standard, node))
        print("done")
    }

    internal func addComponent() {
        scene?.rootNode.addChildNode(C3D(ComponentTemplates.standard))
        print("done")
    }
}
