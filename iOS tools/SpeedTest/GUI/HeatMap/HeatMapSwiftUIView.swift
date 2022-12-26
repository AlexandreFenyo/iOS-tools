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
//    static let step2String = [ "step 1/5: select your floor plan (click on the Select your floor plan green button)", "Come back here after having started a TCP Flood Discard action on a target.\nThe target must be the same until the heat map is built.\n- to estimate the Wi-Fi internal throughput between local hosts, either select a target on the local wired network, or select a target that is as near as possible as an access point;\n- to estimate the Internet throughput with each location on the local Wi-Fi network, select a target on the Internet, like flood.eowyn.eu.org.", "step 2/5: go near an access point or repeater and click on its location on the map.\n[ This will take a speed measure, wait for the throughput to become steady before clicking on the map. ]" ]
    static let step2String = [ "step 1/5: select your floor plan (click on the Select your floor plan green button)", "Come back here after having started a TCP Flood Discard action on a target.\nThe target must be the same until the heat map is built.\n- to estimate the Wi-Fi internal throughput between local hosts, either select a target on the local wired network, or select a target that is as near as possible as an access point;\n- to estimate the Internet throughput with each location on the local Wi-Fi network, select a target on the Internet, like flood.eowyn.eu.org.", "step 2/5: go near an access point or repeater and click on its location on the map.\n[ This will take a speed measure, wait for the throughput to become steady before clicking on the map. ]" ]

    @Published var input_map_image: UIImage?
    @Published var idw_values = Set<IDWValue<Float>>()
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

    @State private var image_last_update = Date()
    @State private var cg_image_prev: CGImage?
    @State private var cg_image_next: CGImage?
    @State private var image_update_ratio: Float = 0

    @State private var last_loc_x: UInt16?
    @State private var last_loc_y: UInt16?

    @State private var idw_values = Set<IDWValue<Float>>()
    @State private var display_steps = false

    @State private var power_scale: Float = 1
    @State private var power_scale_radius: Float = 1
    @State private var toggle_radius = false

    @State private var distance_cache: DistanceCache? = nil

    let timer_get_average = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let timer_set_speed = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    let timer_create_map = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
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
    
    private func updateMap(debug_x: UInt16? = nil, debug_y: UInt16? = nil) {
        let width = UInt16(model.input_map_image!.cgImage!.width)
        let height = UInt16(model.input_map_image!.cgImage!.height)
        var idw_image = IDWImage(width: width, height: height)
        if let max = (model.idw_values.union(idw_values).filter { $0.type == .probe }.max { $0.v < $1.v }?.v) {
            if max != 0 {
                var values = model.idw_values.union(idw_values).filter { $0.type == .probe }.map {
                    IDWValue<UInt16>(x: $0.x, y: $0.y, v: UInt16($0.v / max * Float(UInt16.max - 1)))
                }
                let aps = model.idw_values.union(idw_values).filter { $0.type == .ap }.map {
                    IDWValue<UInt16>(x: $0.x, y: $0.y, v: UInt16($0.v), type: .ap)
                }
                values.append(contentsOf: aps)
                let _ = values.map { idw_image.addValue($0) }
            }
        }
        Task {
            let new_vertices = idw_image.getValues().filter { $0.type == .ap }.map { CGPoint(x: Double($0.x), y: Double($0.y)) }

            let need_update_cache = distance_cache == nil || Set(new_vertices) != Set(distance_cache!.vertices)
            cg_image_prev = cg_image_next
            
            var new_distance_cache: DistanceCache?
            (cg_image_next, new_distance_cache) = await idw_image.computeCGImageAsync(power_scale: power_scale, power_scale_radius: toggle_radius ? power_scale_radius : 0, debug_x: debug_x, debug_y: debug_y, distance_cache: need_update_cache ? nil : distance_cache)
            if let new_distance_cache {
                distance_cache = new_distance_cache
            }
            image_last_update = Date()
            image_update_ratio = 0
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
                            model.idw_values = model.idw_values.union(idw_values)
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
                        if cg_image_prev != nil {
                            // Image(decorative: cg_image_prev!, scale: 1.0).resizable().aspectRatio(contentMode: .fit).opacity(1.0 - Double(image_update_ratio))
                            // à 0,7, je suis plus clair, à 0,5 je suis encore plus clair - la couleur normale est celle affichée pendant seulement 0,2s
                            Image(decorative: cg_image_prev!, scale: 1.0).resizable().aspectRatio(contentMode: .fit)//.opacity(image_update_ratio < 0.8 ? 1.0 : 1.0)
                        }

                        if cg_image_next != nil {
                            // Image(decorative: cg_image_next!, scale: 1.0).resizable().aspectRatio(contentMode: .fit).opacity(Double(image_update_ratio))
                            Image(decorative: cg_image_next!, scale: 1.0).resizable().aspectRatio(contentMode: .fit).opacity(Double(image_update_ratio))
                        }

                        Image(uiImage: model.input_map_image!)
                            .resizable().aspectRatio(contentMode: .fit).grayscale(1.0).opacity(0.2)
                    }
                    .overlay {
                        GeometryReader { geom in
                            Rectangle().foregroundColor(.gray).opacity(0.01)
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                        .onEnded { position in
                                            idw_values.removeAll()
                                            let loc_screen = position.location
                                            var xx = Int(loc_screen.x / geom.size.width * Double(model.input_map_image!.cgImage!.width))
                                            var yy = Int((geom.size.height - loc_screen.y) / geom.size.height * Double(model.input_map_image!.cgImage!.height))
                                            if xx < 0 { xx = 0 }
                                            if yy < 0 { yy = 0 }
                                            if xx >= model.input_map_image!.cgImage!.width { xx = model.input_map_image!.cgImage!.width - 1 }
                                            if yy >= model.input_map_image!.cgImage!.height { yy = model.input_map_image!.cgImage!.height - 1 }
                                            last_loc_x = UInt16(xx)
                                            last_loc_y = UInt16(yy)
                                            
                                            idw_values.insert(IDWValue(x: last_loc_x!, y: last_loc_y!, v: 200, type: .ap))
                                            idw_values.insert(IDWValue(x: last_loc_x!, y: last_loc_y!, v: speed, type: .probe))
                                            updateMap(debug_x: last_loc_x, debug_y: last_loc_y)
                                        }
                                )
                        }
                    }
                }
                
                Slider(value: $power_scale, in: 0...5)
                HStack {
                    Toggle("xxx", isOn: $toggle_radius)
                    Slider(value: $power_scale_radius, in: 0...600).disabled(!toggle_radius)
                }

                Spacer()
                HStack {
                    // pour débugger opacity
                    Text("average throughput: \(UInt64(speed)) bit/s - opacity: \(image_update_ratio)")
                    //                    Text("average throughput: \(UInt64(speed)) bit/s")
                        .font(.system(size: 16).monospacedDigit())
                        .onReceive(timer_set_speed) { _ in
                            // Manage speed
                            let interval_speed = Float(Date().timeIntervalSince(self.average_last_update))
                            let UPDATE_SPEED_DELAY: Float = 1.0
                            if interval_speed < UPDATE_SPEED_DELAY {
                                speed = average_prev * (UPDATE_SPEED_DELAY - interval_speed) / UPDATE_SPEED_DELAY + average_next * interval_speed / UPDATE_SPEED_DELAY
                            } else {
                                speed = average_next
                            }
                            
                            // Manage heat maps
                            let interval_image = Float(Date().timeIntervalSince(self.image_last_update))
                            let UPDATE_IMAGE_DELAY: Float = 1.0
                            if interval_image < UPDATE_IMAGE_DELAY {
                                image_update_ratio = interval_image
                            } else {
                                image_update_ratio = 1
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
                                if let probe = (idw_values.first { $0.type == .probe }) {
                                    // pour tester des variations importantes de speed
                                    var _v = speed
                                    /*
                                     let r = arc4random()
                                     if r < UInt32.max / 5 {
                                     _v = 1000000.0
                                     }
                                     if r >= UInt32.max / 5 && r <= UInt32.max / 3 {
                                     _v = 20000000.0
                                     }
                                     */

                                    let replace_probe = IDWValue(x: probe.x, y: probe.y, v: _v, type: probe.type)
                                    idw_values = idw_values.filter { $0.type == .ap }
                                    idw_values.insert(replace_probe)
                                }
                                updateMap()
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
