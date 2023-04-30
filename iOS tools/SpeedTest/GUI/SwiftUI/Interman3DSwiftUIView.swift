//
//  IntermanSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/03/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

import Foundation
import SwiftUI
import SceneKit

// structure de données
//

struct Interman3DSwiftUIView: View {
    public weak var master_view_controller: MasterViewController?

    @ObservedObject var model = Interman3DModel.shared

    static func get3DScene() -> SCNScene? {
      let scene = SCNScene(named: "Interman 3D Scene.scn")
        Interman3DModel.shared.scene = scene
        
        let camera = scene!.rootNode.childNode(withName: "camera", recursively: true)
        camera!.camera!.usesOrthographicProjection = true
        
        return scene
    }
    
    var scene = get3DScene()
    
    var body: some View {
        ZStack {
            SceneView(
            scene: scene,
            options: [ .allowsCameraControl ])
            .edgesIgnoringSafeArea(.all)
          VStack {
            Spacer()

            HStack {
              HStack {
                  Button {
                      model.addComponent()
                  } label: {
                      Text("create")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }
              }

              Spacer()
              Text("salut").foregroundColor(.white)
              Spacer()
                Button {
                    model.testComponent()
                } label: {
                    Text("update")
                    Image(systemName: "xmark.circle.fill").imageScale(.large)
                }
            }
            .padding(8)
            .cornerRadius(14)
            .padding(12)
          }
        }
    }
}
