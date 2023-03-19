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

public class Interman3DModel : ObservableObject {
    static let shared = Interman3DModel()
    public var scene: SCNScene?
    
    public init() {
        print("MANAGER INIT")
    }
    
    public func tst() {
        print("MANAGER TEST")
        addNode()
    }

    public func addNode() {
        guard let _scene = SCNScene(named: "Interman 3D Standard Node.scn") else {
            fatalError("can not load Node scene")
        }
        scene?.rootNode.addChildNode(_scene.rootNode.clone())
        print("done")
    }
    
}
