//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit
import PhotosUI

// app équivalente : WiFi All In One Network Survey (18,99€)

// ex.: https://gist.github.com/ricardo0100/4e04edae0c8b0dff68bc2fba6ef82bf5
// https://www.hackingwithswift.com/books/ios-swiftui/integrating-core-image-with-swiftui

public class MapViewModel : ObservableObject {
    static let shared = MapViewModel()
    @Published var input_map_image: UIImage?
}

@MainActor
struct HeatMapSwiftUIView: View {
    let heatmap_view_controller: HeatMapViewController
    
    @ObservedObject var model = MapViewModel.shared
    @State private var showing_map_picker = false

    @State private var speed: Float = 0

    @State private var average_last_update = Date()
    @State private var average_prev: Float = 0
    @State private var average_next: Float = 0

    let timer_get_average = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Heat Map Builder")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                    .sheet(isPresented: $showing_map_picker) {
                        ImagePicker(image: $model.input_map_image)
                    }
                Spacer()
            }.background(Color(COLORS.toolbar_background))
            
            VStack {
                HStack() {
                    
                    HStack(alignment: .top) {
                        Button {
                            showing_map_picker = true
                        } label: {
                            VStack {
                                Image(systemName: "map").resizable().frame(width: 40, height: 30)
                                Text("Select your floor plan").font(.footnote).frame(maxWidth: 200)
                            }
                        }
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up.on.square").resizable().frame(width: 30, height: 30)
                                Text("TCP flood discard").font(.footnote)
                            }
                        }
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.down.on.square").resizable().frame(width: 30, height: 30)
                                Text("TCP flood chargen").font(.footnote)
                            }
                        }
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                    }.padding()
                    
                }
                
                if model.input_map_image != nil {
                    Image(uiImage: model.input_map_image!)
                        .resizable().aspectRatio(contentMode: .fit).grayscale(1.0)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                  print("\(value.location)")
                                }
                                .onEnded { _ in
//                                  self.position = .zero
                                }
                        )
                }
                Spacer()
                HStack {
                    Text("average throughput: \(UInt64(speed)) bit/s")
                        .font(.system(size: 16).monospacedDigit())
                        .onReceive(timer) { _ in
                            let interval = Float(Date().timeIntervalSince(self.average_last_update))
                            let UPDATE_DELAY: Float = 1.0
                            if interval < UPDATE_DELAY {
                                speed = average_prev * (UPDATE_DELAY - interval) / UPDATE_DELAY + average_next * interval / UPDATE_DELAY
                            } else {
                                speed = average_next
                            }
                        }
                        .onReceive(timer_get_average) { _ in
                            Task {
                                self.average_last_update = Date()
                                self.average_prev = self.average_next
                                self.average_next = await heatmap_view_controller.master_view_controller!.detail_view_controller!.ts.getAverage()
                            }
                        }
                        .padding()
                    Spacer()
                }
            }
            .background(Color(COLORS.right_pannel_scroll_bg))
            .cornerRadius(15).padding(10)
            
            Button("Hide map") {
                heatmap_view_controller.dismiss(animated: true)
            }.padding()
            
        }.background(Color(COLORS.right_pannel_bg))
    }
}
