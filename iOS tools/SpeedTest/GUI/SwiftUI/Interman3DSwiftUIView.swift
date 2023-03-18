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
    
    
    
    var body: some View {
        ZStack {
          SceneView(
            // 1
            scene: scene,
            // 2
//            pointOfView: setUpCamera(planet: viewModel.selectedPlanet),
            // 3
            options: .allowsCameraControl)
            // 4
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
                  } label: {
                  Image(systemName: "arrow.backward.circle.fill")
                }
                  
                  Button {
                  } label: {
                      Image(systemName: "arrow.forward.circle.fill")
                }
              }

              Spacer()
              Text("salut").foregroundColor(.white)
              Spacer()
                Button {
                    
                } label: {
                  Image(systemName: "xmark.circle.fill")
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
