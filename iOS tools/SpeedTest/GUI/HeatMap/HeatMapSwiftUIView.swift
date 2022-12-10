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
    //    static let step2String = [ "step 1/5: select your floor plan (click on the Select your floor plan green button)", ".eowyn.eu.org.", "step 2/5: go near an access point or repeater and click on its location on the map.\n[ This will take a speed measure, wait for the throughput to become steady before clicking on the map. ]" ]
    static let step2String = [ "step 1/5: select your floor plan (click on the Select your floor plan green button)", "Come back here after having started a TCP Flood Discard action on a target.\nThe target must be the same until the heat map is built.\n- to estimate the Wi-Fi internal throughput between local hosts, either select a target on the local wired network, or select a target that is as near as possible as an access point;\n- to estimate the Internet throughput with each location on the local Wi-Fi network, select a target on the Internet, like flood.eowyn.eu.org.", "step 2/5: go near an access point or repeater and click on its location on the map.\n[ This will take a speed measure, wait for the throughput to become steady before clicking on the map. ]" ]
    
    @Published var input_map_image: UIImage?
    @Published var idw_values = Set<IDWValue>()
    @Published var step = 0
}

@MainActor
struct HeatMapSwiftUIView: View {
//    private var my_memory_tracker = MyMemoryTracker("HeatMapSwiftUIView")
    
    init(_ heatmap_view_controller: HeatMapViewController) {
        self.heatmap_view_controller = heatmap_view_controller
    }
    
    public func cleanUp() { }
    
    weak var heatmap_view_controller: HeatMapViewController?
    
    @ObservedObject var model = MapViewModel.shared
    @State private var showing_map_picker = false
    
    @State private var speed: Float = 0
    
    @State private var average_last_update = Date()
    @State private var average_prev: Float = 0
    @State private var average_next: Float = 0
    
    @State private var cg_image_prev: CGImage?
    @State private var cg_image_next: CGImage?
    
    @State private var idw_values = Set<IDWValue>()
    @State private var display_steps = false
    
    let timer_get_average = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let timer_set_speed = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    let timer_create_map = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    //    @State var cpt = 0
    //    let timer2 = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    //   @State var cpt2 = 0
    
    /*
     private func screenToMap(_ x: UInt16, _ y: UInt16) -> (x: UInt16, y: UInt16) {
     let width = Float(model.input_map_image!.cgImage!.width)
     let height = Float(model.input_map_image!.cgImage!.height)
     
     }*/
    
    /*
     private func MapToScreen(_ x: UInt16, _ y: UInt16) -> (x: UInt16, y: UInt16) {
     
     }*/
    
    private func updateSteps() {
        if model.input_map_image == nil { model.step = 0 }
        else {
            if average_next == 0 {
                model.step = 1
            } else {
                model.step = 2
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Heat Map Builder")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                    .sheet(isPresented: $showing_map_picker) {
                        ImagePicker(image: $model.input_map_image, idw_values: $model.idw_values)
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
                                Image(systemName: "map").resizable().frame(width: 30, height: 30)
                                Text("Select your floor plan").font(.footnote).frame(maxWidth: 200)
                            }
                        }
                        .disabled(model.input_map_image != nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                        } label: {
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right").resizable().frame(width: 35, height: 30)
                                Text("Add an access point or repeater").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.down.on.square").resizable().frame(width: 30, height: 30)
                                Text("Add a measure").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                            model.input_map_image = nil
                            model.idw_values = Set<IDWValue>()
                            updateSteps()
                        } label: {
                            VStack {
                                Image(systemName: "trash").resizable().frame(width: 30, height: 30)
                                Text("Reset all").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up").resizable().frame(width: 30, height: 30)
                                Text("Share your map").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                    }.padding(.top)
                }
                
                HStack {
                    Spacer()
                    Text(MapViewModel.step2String[model.step])
                        .font(Font.system(size: 14).bold())
                        .foregroundColor(.white)
                        .padding(5.0)
                    Spacer()
                }
                .background(.gray)
                .cornerRadius(15).padding(.bottom).padding(.leading).padding(.trailing)
                .opacity(display_steps ? 1.0 : 0.8).animation(.default, value: display_steps)
                .onChange(of: cg_image_next, perform: { _ in
                    updateSteps()
                })
                
                if model.input_map_image != nil {
                    ZStack {
                        if cg_image_next != nil {
                            Image(decorative: cg_image_next!, scale: 1.0)//.opacity(Double(cpt2) / 50.0)
                                .resizable().aspectRatio(contentMode: .fit)
                        }
                        Image(uiImage: model.input_map_image!)
                            .resizable().aspectRatio(contentMode: .fit).grayscale(1.0).opacity(0.1)
                    }
                    .overlay {
                        GeometryReader { geom in
                            Rectangle().foregroundColor(.gray).opacity(0.01)
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                        .onChanged { position in
                                            idw_values.removeAll()
                                            var loc_screen = position.location
                                            var xx = Int(loc_screen.x / geom.size.width * Double(model.input_map_image!.cgImage!.width))
                                            var yy = Int((geom.size.height - loc_screen.y) / geom.size.height * Double(model.input_map_image!.cgImage!.height))
                                            
                                            if xx < 0 { xx = 0 }
                                            if yy < 0 { yy = 0 }
                                            if xx >= model.input_map_image!.cgImage!.width { xx = model.input_map_image!.cgImage!.width - 1 }
                                            if yy >= model.input_map_image!.cgImage!.height { yy = model.input_map_image!.cgImage!.height - 1 }
                                            idw_values.insert(IDWValue(x: UInt16(xx), y: UInt16(yy), v: 200, type: .ap))
                                            idw_values.insert(IDWValue(x: UInt16(xx), y: UInt16(yy), v: IDWValueType.max, type: .probe))
                                        }
                                )
                        }
                    }
                }
                
                Spacer()
                HStack {
                    Text("average throughput: \(UInt64(speed)) bit/s")
                        .font(.system(size: 16).monospacedDigit())
                        .onReceive(timer_set_speed) { _ in
                            let interval = Float(Date().timeIntervalSince(self.average_last_update))
                            let UPDATE_DELAY: Float = 1.0
                            if interval < UPDATE_DELAY {
                                speed = average_prev * (UPDATE_DELAY - interval) / UPDATE_DELAY + average_next * interval / UPDATE_DELAY
                            } else {
                                speed = average_next
                            }
                        }
                        .onReceive(timer_get_average) { _ in
                            display_steps.toggle()
                            Task {
                                if let heatmap_view_controller {
                                    average_last_update = Date()
                                    average_prev = average_next
                                    average_next = await heatmap_view_controller.master_view_controller!.detail_view_controller!.ts.getAverage()
                                    if average_prev == 0.0 {
                                        average_prev = average_next
                                    }
                                }
                            }
                        }
                        .onReceive(timer_create_map) { _ in
                            if model.input_map_image != nil {
                                let width = UInt16(model.input_map_image!.cgImage!.width)
                                let height = UInt16(model.input_map_image!.cgImage!.height)

                                var idw_image = IDWImage(width: width, height: height)
                                for _ in model.idw_values {
                                    //                                    _ = idw_image.addValue(val)
                                }
                                for value in idw_values {
                                    _ = idw_image.addValue(value)
                                }
                                
                                Task {
                                    cg_image_next = await idw_image.computeCGImageAsync()
                                }
                            }
                        }
                        .padding()
                    Spacer()
                }
            }
            .background(Color(COLORS.right_pannel_scroll_bg))
            .cornerRadius(15).padding(10)
            
            Button("Hide map") {
                heatmap_view_controller?.dismiss(animated: true)
            }.padding()
        }.background(Color(COLORS.right_pannel_bg))
    }
}
