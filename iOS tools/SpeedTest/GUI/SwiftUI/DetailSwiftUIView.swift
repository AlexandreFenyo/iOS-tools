//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

@MainActor
struct DetailSwiftUIView: View {
    public let view: UIView
    public let master_view_controller: MasterViewController
    
    public class DetailViewModel : ObservableObject {
        @Published private(set) var family: Int32? = nil
        @Published private(set) var address_str : String = "valeur initiale dans le binaire"

        public func setText(_ str: String) {
            print("setText() dans le modèle: \(str)")
            address_str = str
        }
        
        public func setButtonsEnabled(_ state: Bool) {
            print("setButtonsEnabled(\(state))")
        }
    }
    
    public func setText(_ str: String) {
        print("setText() dans la vue swiftUI: \(str)")
        model.setText(str)
    }

    @ObservedObject var model = DetailViewModel()
    
    var body: some View {
        ScrollView {
            
            VStack {
                Text(model.address_str == nil ? "none" : model.address_str)
                
                HStack {
                    Button {
                        print("bouton appuyé")
                        setText("valeur positionnée par le bouton")
                    } label: {
                        Text("bouton")
                    }
                }
            }
        } // ScrollView
    }
}
