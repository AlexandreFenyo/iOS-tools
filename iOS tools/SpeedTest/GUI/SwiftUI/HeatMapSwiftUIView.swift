//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

// app équivalente : WiFi All In One Network Survey (18,99€)

@MainActor
struct HeatMapSwiftUIView: View {
    let heatmap_view_controller: HeatMapViewController

    @State private var scope: NodeType = .internet
    @State private var foo = 0

    @State private var isPermanent = true

    @State private var target_name: String = ""
    @State private var target_ip: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Heat Map Builder")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                Spacer()
            }.background(Color(COLORS.toolbar_background))
            
            VStack {
                Spacer()
                HStack() {
                    Spacer()
                    Text("slaut")
                    Spacer()
                }
                Spacer()
            }
                .background(Color(COLORS.right_pannel_scroll_bg))
                .cornerRadius(15).padding(10)

            Button("Hide map") {
                heatmap_view_controller.dismiss(animated: true)
            }.padding()
            
        }.background(Color(COLORS.right_pannel_bg))
    }
}
