//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

var delta: CGFloat?

struct DetailSwiftUIView: View {
    private let ts = TimeSeries()
    
    public let view: UIView
    
    var body: some View {
        GeometryReader { geomx in
            ScrollView {
                VStack {
                    
                    Text("sdalut")
                    Text("sezffezzefalut")
                    Text("salut")
                    Text("salut")
                    Text("salutrt")
                    
                    ZStack {
                        GeometryReader { geom in
                            SpriteView(scene: {
                                print("(re-)create scene")
                                let scene = SKScene()
                                scene.size = CGSize(width: geom.size.width, height: 300)
                                scene.scaleMode = .fill
                                let chart_node = SKChartNode(ts: ts, full_size: CGSize(width: geom.size.width, height: 300), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: nil)
                                scene.addChild(chart_node)
                                /*
                                 if delta == nil {
                                 delta = geom.frame(in: CoordinateSpace.global).minY
                                 }
                                 print("delta:\(delta)")*/
                                chart_node.registerGestureRecognizers(view: view, delta: 164)
                                
                                chart_node.position = CGPoint(x: 0, y: 0)
                                
                                ts.add(TimeSeriesElement(date: Date(), value: 5.0))
                                
                                
                                
                                return scene
                            }()).frame(width: geom.size.width, height: 300, alignment: .center)
                            
                            //                    Text("height: \(geom.frame(in: CoordinateSpace.global).minY)")
                            
                        }
                        
                        
                        
                    }.frame(width: geomx.size.width, height: 300, alignment: .center)
                    
                }
                
                Text("Séparation")
                
                Button {
                } label: {
                    Label("Level 1", systemImage: "rectangle.split.2x2")
                }
                //           }
                
                
                
            }
        }
    }
}

/*
 struct DetailSwiftUIView_Previews: PreviewProvider {
 static var previews: some View {
 DetailSwiftUIView(nil)
 }
 }
 */
