//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

class GraphScene: SKScene {
    
}

struct DetailSwiftUIView: View {
    private var chart_node : SKChartNode?
    private let ts = TimeSeries()
    
    var scene: SKScene {
        let scene = GraphScene()
        scene.size = CGSize(width: 300, height: 400)
        scene.scaleMode = .fill
        
        let chart_node = SKChartNode(ts: ts, full_size: CGSize(width: 200, height: 200), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: nil)
        
        scene.addChild(chart_node)
        //        chart_node.position = CGPoint(x: 0, y: 0)
        //        chart_node.registerGestureRecognizers(view: view)
        
        return scene
    }
    
    var body: some View {
        ScrollView {
            
            Text("salut")
            SpriteView(scene: scene)
                .frame(width: 300, height: 400)
                .ignoresSafeArea()
            Text("salut2")
            SpriteView(scene: scene)
                .frame(width: 300, height: 400)
                .ignoresSafeArea()
        }
        
    }
}

struct DetailSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSwiftUIView()
    }
}
