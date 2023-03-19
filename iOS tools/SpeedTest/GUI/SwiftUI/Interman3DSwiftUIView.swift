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
    static func get3DScene() -> SCNScene? {
      let scene = SCNScene(named: "Interman 3D Scene.scn")
//      applyTextures(to: scene)
      return scene
    }
    
    var scene = get3DScene()
    
    private func addNode() {
        guard let _scene = SCNScene(named: "Interman 3D Standard Node.scn") else {
            fatalError("can not load Node scene")
        }
        scene?.rootNode.addChildNode(_scene.rootNode.clone())
        print("done")
    }
    
    var body: some View {
        ZStack {
            SceneView(
            scene: scene,
//            pointOfView: setUpCamera(planet: viewModel.selectedPlanet),
            options: [.allowsCameraControl])
//            .background(ColorPalette.secondary)
            .edgesIgnoringSafeArea(.all)
          VStack {
/*
              if let planet = viewModel.selectedPlanet {
              VStack {
                PlanetInfoRow(title: "Length of year", value: planet.yearLength)
                PlanetInfoRow(title: "Number of moons", value: "\(planet.moonCount)")
                PlanetInfoRow(title: "Namesake", value: planet.namesake)
              }
              .padding(8)
              .background(ColorPalette.primary)
              .cornerRadius(14)
              .padding(12)
            }
*/
            Spacer()

            HStack {
              HStack {
                  Button {
                      addNode()
                  } label: {
                      Text("TEST")
                      Image(systemName: "arrow.backward.circle.fill").imageScale(.large)
                  }
              }

              Spacer()
              Text("salut").foregroundColor(.white)
              Spacer()
                Button {
                    
                } label: {
                  Image(systemName: "xmark.circle.fill").imageScale(.large)
                }
            }
            .padding(8)
//            .background(ColorPalette.primary)
            .cornerRadius(14)
            .padding(12)
          }
        }
    }
}
