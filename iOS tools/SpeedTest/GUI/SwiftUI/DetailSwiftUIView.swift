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
        @Published private(set) var address_str : String = "valeur initiale1"
        
        public func setButtonsEnabled(_ state: Bool) {
            print("setButtonsEnabled(\(state))")
        }
    }
    
    @ObservedObject var model = DetailViewModel()
    
    var body: some View {
        ScrollView {
            
            VStack {
                Text(model.address_str == nil ? "none" : model.address_str)
                
                HStack {
                    Button {
                        // action si click
                    } label: {
                        Text("bouton")
                    }
                }
            }
        } // ScrollView
    }
}
