//
//  IntermanSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/03/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

import Foundation
import SwiftUI
import SpriteKit

// structure de données
// 

struct Interman2DSwiftUIView: View {
    private func get2DScene(size: CGSize) -> SKScene {
        let scene = Interman2DScene(size: size)
        scene.scaleMode = .fill
        let circle = SKShapeNode(circleOfRadius: 10)
        circle.position = CGPointMake(size.width / 2, size.height / 2)
        circle.strokeColor = .systemRed
        circle.glowWidth = 1.0
        circle.fillColor = .white
        scene.addChild(circle)
        return scene
    }
    
    var body: some View {
        VStack {
            Text("Interman").background(.blue)
            GeometryReader { geometry in
                SpriteView(scene: get2DScene(size: geometry.size))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}