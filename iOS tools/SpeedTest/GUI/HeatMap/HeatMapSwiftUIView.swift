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
    static let step2String = [
        "step 1/5: select your floor plan (click on the Select your floor plan green button)",
        "Come back here after having started a TCP Flood Discard action on a target.\nThe target must be the same until the heat map is built.\n- to estimate the Wi-Fi internal throughput between local hosts, either select a target on the local wired network, or select a target that is as near as possible as an access point;\n- to estimate the Internet throughput with each location on the local Wi-Fi network, select a target on the Internet, like flood.eowyn.eu.org.",
        "step 2/5:\n- at the bottom left of the map, you can see a white access point blinking;\n- go near an access point;\n- click on its location on the map to move the white access point to your location on the map;\n- on the vertical left scale, you can see the real time network speed;\n- when the speed is stable, associate this value to your access point by clicking on Add an access point or probe.",
        "step 3/5:\n- your first access point color has changed to black, this means it has been registered with the speed value at its location;\n- a new white access point is ready for a new value, at the bottom left of the map;\n- you may optionally want to take a measure far from an access point. In that case, click again on Add an access point or probe to change the image of the white access point to a probe one;\n- move to a new location to take a new measure;\n- click on the location on the map to move the white access point or probe to your location on the map;\n- when the speed on the vertical left scale is stable, associate this value to your location by clicking on Add an access point or probe.",
        "step 4/4:\n- you see a triangle since you have reached three measures;\n- the last one is located on the top bottom white access point;\n- you can optionally click again on Add an access point or probe to replace the white access point with a white probe;\n- click on the map to change the location of this third measure;\n- try different positions of the horizontal sliders to adjust the map;\n- click on Add an access point or probe to associate the speed measure to your current location and add another white access point at the bottom left of the map;\n- when finished, remove the latest white access point or probe by clicking Share your map. This will also let you save the heat map."
    ]
    
    @Published var input_map_image: UIImage?
    @Published var idw_values = Array<IDWValue<Float>>()
    @Published var step = 0
}

private let NEW_PROBE_X: UInt16 = 100
private let NEW_PROBE_Y: UInt16 = 50
private let NEW_PROBE_VALUE: Float = 10000000.0
private let SCALE_WIDTH: CGFloat = 30
private let LOWEST_MAX_SCALE: Float = 1000

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
    
    @State private var average_last_update = Date()
    @State private var average_prev: Float = 0
    @State private var average_next: Float = 0
    
    @State private var image_last_update = Date()
    @State private var cg_image_prev: CGImage?
    @State private var cg_image_next: CGImage?
    @State private var image_update_ratio: Float = 0
    
    @State private var last_loc_x: UInt16?
    @State private var last_loc_y: UInt16?
    
    @State private var idw_transient_value: IDWValue<Float> = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
    
    @State private var display_steps = false
    
    @State private var power_scale: Float = 1
    @State private var power_scale_radius: Float = 1
    @State private var toggle_radius = true
    
    @State private var distance_cache: DistanceCache? = nil
    
    // à chaque mesure de débit, l'acteur TimeSeries calcule average qui est une moyenne temporelle pondérée par une exponentielle
    // toutes les secondes, average_prev et average_next sont mis à jour à partir des valeurs de average
    // tous les centièmes de seconde, speed est mis à jour comme un ratio entre average_prev et average_next
    @State private var speed: Float = 0
    @State private var max_scale: Float = LOWEST_MAX_SCALE
    
    let timer_get_average = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let timer_set_speed = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    let timer_create_map = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    private func updateSteps() {
        if model.input_map_image == nil { model.step = 0 }
        else {
            if average_next == 0 {
                model.step = 1
            } else {
                if model.idw_values.count == 0 {
                    model.step = 2
                } else {
                    if model.idw_values.count == 1 {
                        model.step = 3
                    } else {
                        model.step = 4
                    }
                }
            }
        }
    }
    
    private func updateMap(debug_x: UInt16? = nil, debug_y: UInt16? = nil) {
        let width = UInt16(model.input_map_image!.cgImage!.width)
        let height = UInt16(model.input_map_image!.cgImage!.height)
        var idw_image = IDWImage(width: width, height: height)
        if let max = (Set(model.idw_values).union(Set([idw_transient_value])).max { $0.v < $1.v }?.v) {
            if max != 0 {
                let values = Set(model.idw_values).union(Set([idw_transient_value])).map {
                    IDWValue<UInt16>(x: $0.x, y: $0.y, v: UInt16($0.v / max * Float(UInt16.max - 1)))
                }
                let _ = values.map { idw_image.addValue($0) }
            }
        }
        Task {
            let new_vertices = idw_image.getValues().map { CGPoint(x: Double($0.x), y: Double($0.y)) }
            
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
                            if idw_transient_value.x == NEW_PROBE_X && idw_transient_value.y == NEW_PROBE_Y {
                                idw_transient_value = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: idw_transient_value.type == .ap ? .probe : .ap)
                            } else {
                                model.idw_values.append(idw_transient_value)
                                idw_transient_value = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right").resizable().frame(width: 35, height: 30)
                                Text("Add an access point or probe").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                            if let last = model.idw_values.popLast() {
                                idw_transient_value = last
                            } else {
                                idw_transient_value = IDWValue(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: idw_transient_value.type)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right.slash").resizable().frame(width: 30, height: 30)
                                Text("Remove access point or probe").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                            model.input_map_image = nil
                            model.idw_values = Array<IDWValue>()
                            distance_cache = nil
                            max_scale = LOWEST_MAX_SCALE
                            idw_transient_value = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
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
                            model.step = 0
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
                        .font(Font.system(size: 7).bold())
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
                            Image(decorative: cg_image_prev!, scale: 1.0).resizable().aspectRatio(contentMode: .fit)
                            
                                .overlay {
                                    GeometryReader { geom in
                                        Image(systemName: idw_transient_value.type == .ap ? "antenna.radiowaves.left.and.right" : "dot.radiowaves.left.and.right")
                                            .colorInvert()
                                            .position(x: CGFloat(idw_transient_value.x) * geom.size.width / CGFloat(cg_image_prev!.width), y: geom.size.height - CGFloat(idw_transient_value.y) * geom.size.width / CGFloat(cg_image_prev!.width))
                                        
                                        // 256 probes displayed at max
                                        let values = model.idw_values.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $0.y }
                                        ForEach(0..<256) { index in
                                            if index < values.count {
                                                let idw_value: IDWValue = values[index]
                                                Image(systemName: idw_value.type == .ap ? "antenna.radiowaves.left.and.right" : "dot.radiowaves.left.and.right")
                                                    .position(x: CGFloat(idw_value.x) * geom.size.width / CGFloat(cg_image_prev!.width), y: geom.size.height - CGFloat(idw_value.y) * geom.size.width / CGFloat(cg_image_prev!.width))
                                            }
                                        }
                                    }
                                }
                        }
                        
                        if cg_image_next != nil {
                            Image(decorative: cg_image_next!, scale: 1.0).resizable().aspectRatio(contentMode: .fit).opacity(Double(image_update_ratio))
                                .overlay {
                                    GeometryReader { geom in
                                        Image(decorative: IDWImage.getScaleImage(power_scale: 1, height: 60)!, scale: 1.0).resizable().frame(width: SCALE_WIDTH)
                                        
                                        
                                        if max_scale != 0 {
                                            let foo: Float = speed / max_scale * (Float(cg_image_next!.height) - 1.0)
                                            let bar = CGFloat(foo)
                                            
                                            Image(systemName: "restart")
                                                .position(x: SCALE_WIDTH, y: speed <= max_scale ? geom.size.height - bar * geom.size.width / CGFloat(cg_image_next!.width) : 0)
                                            
                                            let foo2 = speed <= max_scale ? geom.size.height - bar * geom.size.width / CGFloat(cg_image_next!.width) + 3 : 0
                                            
                                            Text("\(UInt64(speed)) bit/s").font(.system(size: 8).monospacedDigit())
                                            //.frame(maxWidth: .infinity, alignment: .trailing)
                                                .position(x: SCALE_WIDTH + 50, y: foo2)
                                            
                                            if foo2 >= 20 {
                                                Image(systemName: "restart")
                                                    .position(x: SCALE_WIDTH, y: 0)
                                                Text("\(UInt64(max_scale)) bit/s").font(.system(size: 8).monospacedDigit())
                                                    .position(x: SCALE_WIDTH + 50, y: 0)
                                            }
                                        }
                                    }
                                }
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
                                            let loc_screen = position.location
                                            var xx = Int(loc_screen.x / geom.size.width * Double(model.input_map_image!.cgImage!.width))
                                            var yy = Int((geom.size.height - loc_screen.y) / geom.size.height * Double(model.input_map_image!.cgImage!.height))
                                            if xx < 0 { xx = 0 }
                                            if yy < 0 { yy = 0 }
                                            if xx >= model.input_map_image!.cgImage!.width { xx = model.input_map_image!.cgImage!.width - 1 }
                                            if yy >= model.input_map_image!.cgImage!.height { yy = model.input_map_image!.cgImage!.height - 1 }
                                            last_loc_x = UInt16(xx)
                                            last_loc_y = UInt16(yy)
                                            let foo = CGFloat(last_loc_x!)
                                            if foo >= SCALE_WIDTH {
                                                idw_transient_value = IDWValue(x: last_loc_x!, y: last_loc_y!, v: speed, type: idw_transient_value.type)
                                                updateMap(debug_x: last_loc_x, debug_y: last_loc_y)
                                            } else {
                                                if idw_transient_value.x == NEW_PROBE_X && idw_transient_value.y == NEW_PROBE_Y {
                                                    idw_transient_value = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: idw_transient_value.type == .ap ? .probe : .ap)
                                                } else {
                                                    let foo = max_scale * Float(last_loc_y!) / Float(model.input_map_image!.cgImage!.height)
                                                    let val = IDWValue<Float>(x: idw_transient_value.x, y: idw_transient_value.y, v: foo, type: idw_transient_value.type)
                                                    model.idw_values.append(val)
                                                    idw_transient_value = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
                                                }
                                            }
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
                    EmptyView().onReceive(timer_set_speed) { _ in // 100 Hz
                        // Manage speed
                        let interval_speed = Float(Date().timeIntervalSince(self.average_last_update))
                        let UPDATE_SPEED_DELAY: Float = 1.0
                        if interval_speed < UPDATE_SPEED_DELAY {
                            speed = average_prev * (UPDATE_SPEED_DELAY - interval_speed) / UPDATE_SPEED_DELAY + average_next * interval_speed / UPDATE_SPEED_DELAY
                            if speed > max_scale { max_scale = speed }
                        } else {
                            speed = average_next
                            if speed > max_scale { max_scale = speed }
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
                    .onReceive(timer_get_average) { _ in // 1 Hz
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
                    .onReceive(timer_create_map) { _ in // 1 Hz
                        if model.input_map_image != nil {
                            idw_transient_value = IDWValue(x: idw_transient_value.x, y: idw_transient_value.y, v: speed, type: idw_transient_value.type)
                            updateMap()
                        }
                    }
//                    .padding()
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
