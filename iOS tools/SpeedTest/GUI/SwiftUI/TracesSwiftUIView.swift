//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import UIKit

struct TracesSwiftUIView: View {
    @State public var model: TracesViewModel = TracesViewModel(traces: "valeur initiale via SwiftUI")
    @State public var txt: String?

    var contr : UIViewController
    
    @Namespace var topID
    @Namespace var bottomID

    var body: some View {
        ScrollViewReader { proxy in
        GeometryReader { geometry in
            ZStack {
                VStack {
                    ScrollView {
                        VStack {
                            Spacer()
                            .id(topID)

                            Text(txt ?? "txt vide")
                            
                            Text(model.title)

                                .id(bottomID)
                            .lineLimit(nil)
                        }.frame(maxWidth: .infinity).background(Color.yellow)
                            .frame(minHeight: geometry.size.height)
                    }
                }

                VStack {
                    HStack {
                        Button {
                            withAnimation {
                                proxy.scrollTo(bottomID)
                            }
                        } label: {
                            Label("Scroll to bottom", systemImage: "network").foregroundColor(.green).padding()
                        }.background(Color.blue).cornerRadius(20)

                        Button {
                            for _ in 1..<200 {
                                // marche pas car il faut créer un nouveau modèle !
                                model.update(str: "text ")
                                // content += "test "
                                // addText("test ")
                            }
                        } label: {
                            Text("Add lines").foregroundColor(.green).padding()
                        }
                        .background(Color.blue).cornerRadius(20).padding()

                        Spacer()
                        
                        Button {
                            model.update(str: "CLEAR")
                        } label: {
                            Label("do not use", systemImage: "arrow.down.to.line.circle.fill").padding()
                        }
                        .background(Color.gray).cornerRadius(20)

                        Button {
//                            model.update(str: "")
  //                          model.traces = "truc"

                            // ca marche en recréant un modèle
                            model = TracesViewModel(traces: model.traces + " - truc affiché par bouton")
                            // alternative qui ne marche pas :
                            // model.traces += " - truc affiché par bouton"
                            // IL faut donc créer un nouveau modèle à chaque modif ! même avec SwiftUI

                            // Exemple qui fonctionne de modification visuelle de composant UIKit
                            // let tabBarController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController
                            // tabBarController?.tabBar.barTintColor = .yellow
                            
                            txt = "plus vide du tout"

                            
                        } label: {
                            Image(systemName: "delete.left.fill").padding()
                        }
                        .background(Color.gray).cornerRadius(20)

                        // arrow.down.to.line.circle.fill
                        // arrow.down.up.line.circle.fill

                    }.background(Color.clear)
                    
                    Spacer()
                }.padding()
                
//                Spacer().background(Color.blue)

            }.background(Color.orange)
            .background(Color(red: 0.478, green: 0.539, blue: 0.613))
        }
    }
    }
}

/*
struct TracesSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TracesSwiftUIView(content2: Binding<String>)
    }
}
*/
