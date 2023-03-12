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

struct IntermanSwiftUIView: View {
    var scene: SKScene {
        let scene = IntermanScene()
        scene.size = CGSize(width: 40, height: 500)
        scene.scaleMode = .fill
        return scene
    }
    
    var body: some View {
        VStack {
            Text("Interman").background(.blue)
            GeometryReader { geometry in
                SpriteView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}
