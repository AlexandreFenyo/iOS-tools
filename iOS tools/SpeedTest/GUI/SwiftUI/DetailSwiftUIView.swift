
// SOLUTION : ne pas mettre le SKScene dans SwiftUI !

import SwiftUI
import SpriteKit

var cpt: Int = 0

@MainActor
struct DetailSwiftUIView: View {
    public let view: UIView
    
    public class DetailViewModel : ObservableObject {
        @Published private(set) var address_str: String = "vide"
        public func setNodeAddress() {
            cpt += 1
            address_str = "\(cpt)"
        }
    }
    @ObservedObject var model = DetailViewModel()
    
    var body: some View {
        ScrollView {
            
            VStack {
                
                VStack {
                    GeometryReader { geom in
                        SpriteView(scene: {
                            
                            print("(re-)create scene")
                            let scene = SKScene()
                            scene.size = CGSize(width: geom.size.width, height: 300)
                            scene.scaleMode = .fill
                            
                            let chart_node = SKChartNode(full_size: CGSize(width: geom.size.width, height: 300), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: nil)
                            scene.addChild(chart_node)
                            chart_node.registerGestureRecognizers(view: view, delta: 40)
                            chart_node.position = CGPoint(x: 0, y: 0)
                            return scene
                        }())
                    }
                    .frame(minWidth: 0, idealWidth: UIScreen.main.bounds.size.width, maxWidth: .infinity, minHeight: 0, idealHeight: 300, maxHeight: .infinity, alignment: .center)
                    
                }
                
                Text(model.address_str)
            }
            
        } // ScrollView
        
    }
}
