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
        "Come back here after having started a TCP Flood Chargen action on a target.\nThe target must be the same until the heat map is built.\n- to estimate the Wi-Fi internal throughput between local hosts, either select a target on the local wired network, or select a target that is as near as possible as an access point;\n- to estimate the Internet throughput with each location on the local Wi-Fi network, select a target on the Internet, like flood.eowyn.eu.org.",
        "step 2/5:\n- at the bottom left of the map, you can see a white access point blinking;\n- go near an access point;\n- click on its location on the map to move the white access point to your location on the map;\n- on the vertical left scale, you can see the real time network speed;\n- when the speed is stable, associate this value to your access point by clicking on Add an access point or probe.",
        "step 3/5:\n- your first access point color has changed to black, this means it has been registered with the speed value at its location;\n- a new white access point is ready for a new value, at the bottom left of the map;\n- you may optionally want to take a measure far from an access point. In that case, click again on Add an access point or probe to change the image of the white access point to a probe one;\n- move to a new location to take a new measure;\n- click on the location on the map to move the white access point or probe to your location on the map;\n- when the speed on the vertical left scale is stable, associate this value to your location by clicking on Add an access point or probe.",
        "step 4/4:\n- you see a triangle since you have reached three measures;\n- the last one is located on the top bottom white access point;\n- you can optionally click again on Add an access point or probe to replace the white access point with a white probe;\n- click on the map to change the location of this third measure;\n- try different positions of the horizontal sliders to adjust the map;\n- click on Add an access point or probe to associate the speed measure to your current location and add another white access point at the bottom left of the map;\n- when finished, remove the latest white access point or probe by enabling the preview switch."
    ]
    
    @Published var input_map_image: UIImage?
    @Published var original_map_image: UIImage?
    @Published var idw_values = Array<IDWValue<Float>>()
    @Published var step = 0
    @Published var max_scale: Float = LOWEST_MAX_SCALE
}

// sliders et toggles de réglage fin des paramètres
private let ENABLE_DEBUG_INTERFACE = false

private let NEW_PROBE_X: UInt16 = 100
private let NEW_PROBE_Y: UInt16 = 50
private let NEW_PROBE_VALUE: Float = 10000000
private let SCALE_WIDTH: CGFloat = 30
private let LOWEST_MAX_SCALE: Float = 1000
private let POWER_SCALE_DEFAULT: Float = 5
private let POWER_SCALE_MAX: Float = 5
private let POWER_SCALE_RADIUS_MAX: Float = 600
private let POWER_SCALE_RADIUS_DEFAULT: Float = 120
private let POWER_BLUR_RADIUS_DEFAULT: CGFloat = 10
private let POWER_BLUR_RADIUS_MAX: CGFloat = 20

class PhotoController: NSObject {
    weak var heatmap_view_controller: HeatMapViewController?
    
    public init(heatmap_view_controller: HeatMapViewController) {
        self.heatmap_view_controller = heatmap_view_controller
    }
    
    @objc private func image(_ image: UIImage,
                             didFinishPhotoLibrarySavingWithError error: Error?,
                             contextInfo: UnsafeRawPointer) {
        print("Image successfully written to camera roll")
        if error != nil {
            popUp("Error saving map", "Access to photos is forbidden. You need to change the access rights in the app configuration pane (click on the wheel button in the toolbar to access the configuration pane)", "OK")
        } else {
            popUp("Map saved", "You can find the heatmap in you photo roll", "OK")
        }
    }
    
    public func popUp(_ title: String, _ message: String, _ ok: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: ok, style: .default)
            alert.addAction(action)
            self.heatmap_view_controller?.present(alert, animated: true)
        }
    }
    
    public func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishPhotoLibrarySavingWithError:contextInfo:)), nil)
    }
}

@MainActor
struct HeatMapSwiftUIView: View {
    //    private var my_memory_tracker = MyMemoryTracker("HeatMapSwiftUIView")
    
    init(_ heatmap_view_controller: HeatMapViewController) {
        self.heatmap_view_controller = heatmap_view_controller
        self.photoController = PhotoController(heatmap_view_controller: heatmap_view_controller)
    }
    
    let photoController: PhotoController
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
    
    @State private var idw_transient_value: IDWValue<Float>? // = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
    
    @State private var display_steps = false
    
    @State private var power_scale: Float = POWER_SCALE_DEFAULT
    @State private var power_scale_radius: Float = POWER_SCALE_RADIUS_DEFAULT
    @State private var power_blur_radius: CGFloat = POWER_BLUR_RADIUS_DEFAULT
    
    // pourrait être associé à un toggle, mais la valeur par défaut de POWER_SCALE_RADIUS_MAX correspond au même aux performances près puisqu'avec toggle_radius à true, il faut calculer un cache des distances au polygone
    @State private var toggle_radius = true
    
    @State private var toggle_help = true
    @State private var toggle_preview = false
    
    @State private var distance_cache: DistanceCache? = nil
    
    // à chaque mesure de débit, l'acteur TimeSeries calcule average qui est une moyenne temporelle pondérée par une exponentielle
    // toutes les secondes, average_prev et average_next sont mis à jour à partir des valeurs de average
    // tous les centièmes de seconde, speed est mis à jour comme un ratio entre average_prev et average_next
    @State private var speed: Float = 0
    
    let timer_get_average = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let timer_set_speed = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    let timer_create_map = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public func cleanUp() { }
    
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
        let transient_set: Set<IDWValue<Float>> = (!toggle_preview && idw_transient_value != nil) ? Set([idw_transient_value!]) : Set()
        
        // on prend toute la plage disponible pour les valeurs des mesures qu'on prend en compte
        let max = model.max_scale
        
        if max != 0 {
            let values = Set(model.idw_values).union(transient_set).map {
                IDWValue<UInt16>(x: $0.x, y: $0.y, v: UInt16($0.v / max * Float(UInt16.max - 1)))
            }
            _ = values.map { idw_image.addValue($0) }
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
                        ImagePicker(image: $model.input_map_image, original_map_image: $model.original_map_image, idw_values: $model.idw_values)
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
                            idw_transient_value = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
                        } label: {
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right").resizable().frame(width: 35, height: 30)
                                Text("Add new probe").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil || idw_transient_value != nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                            model.idw_values.append(idw_transient_value!)
                            idw_transient_value = nil
                        } label: {
                            VStack {
                                Image(systemName: "dot.radiowaves.left.and.right").resizable().frame(width: 35, height: 30)
                                Text("Save measure").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil || idw_transient_value == nil)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                            if idw_transient_value != nil {
                                idw_transient_value = nil
                            } else {
                                _ = model.idw_values.popLast()
                            }
                        } label: {
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right.slash").resizable().frame(width: 30, height: 30)
                                Text("Undo").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil || model.idw_values.count == 0)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                        
                        Button {
                            model.input_map_image = nil
                            model.idw_values = Array<IDWValue>()
                            distance_cache = nil
                            model.max_scale = LOWEST_MAX_SCALE
                            power_scale = POWER_SCALE_DEFAULT
                            power_scale_radius = POWER_SCALE_RADIUS_DEFAULT
                            toggle_help = false
                            toggle_preview = false
                            idw_transient_value = nil // IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
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
                            if model.original_map_image == nil || model.max_scale == 0 { return }
                            let image = model.original_map_image!
                            let width = image.cgImage!.width
                            let height = image.cgImage!.height
                            let screen_width = model.input_map_image?.cgImage!.width
                            let screen_height = model.input_map_image?.cgImage!.height
                            let factor_x = Float(width) / Float(screen_width!)
                            let factor_y = Float(height) / Float(screen_height!)
                            var idw_image = IDWImage(width: UInt16(width), height: UInt16(height))
                            let max = model.max_scale
                            let values = Set(model.idw_values).map {
                                IDWValue<UInt16>(x: UInt16(Float($0.x) * factor_x), y: UInt16(Float($0.y) * factor_y), v: UInt16($0.v / max * Float(UInt16.max - 1)))
                            }
                            _ = values.map { idw_image.addValue($0) }
                            
                            photoController.popUp("Saving map", "The heat map will be computed in the background, a pop-up will appear when it is done. It may take up to one minute approximatively.", "OK")
                            
                            Task {
                                let (cg_image, _) = await idw_image.computeCGImageAsync(power_scale: power_scale, power_scale_radius: power_scale_radius * factor_x, distance_cache: nil)
                                
                                let ui_image = UIImage(cgImage: cg_image!)
                                photoController.saveImage(image: ui_image)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up").resizable().frame(width: 30, height: 30)
                                Text("Share your map").font(.footnote)
                            }
                        }
                        .disabled(model.input_map_image == nil || idw_transient_value != nil || model.idw_values.count < 3)
                        .accentColor(Color(COLORS.standard_background))
                        .frame(maxWidth: 200)
                    }.padding(.top)
                }
                
                if ENABLE_DEBUG_INTERFACE {
                    if toggle_help {
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
                    }
                } else {
                    HStack {
                        if model.input_map_image != nil && average_next == 0 {
                            Spacer()
                            Text(MapViewModel.step2String[1])
                                .font(Font.system(size: 12).bold())
                                .foregroundColor(.white)
                                .padding(5.0)
                            Spacer()
                        }
                    }
                    .background(.gray)
                    .cornerRadius(15).padding(.bottom).padding(.leading).padding(.trailing)
                    .opacity(display_steps ? 1.0 : 0.8).animation(.default, value: display_steps)
                }
                
                if model.input_map_image != nil {
                    ZStack {
                        if cg_image_prev != nil {
                            Image(decorative: cg_image_prev!, scale: 1.0)
                                .resizable()
                                .blur(radius: power_blur_radius, opaque: true)
                                .clipped()
                                .aspectRatio(contentMode: .fit)
                                .overlay {
                                    GeometryReader { geom in
                                        if idw_transient_value != nil {
                                            Image(systemName: "dot.radiowaves.left.and.right")
                                                .resizable().frame(width: 40, height: 30)
                                                .colorInvert()
                                                .position(x: CGFloat(idw_transient_value!.x) * geom.size.width / CGFloat(cg_image_prev!.width), y: geom.size.height - CGFloat(idw_transient_value!.y) * geom.size.width / CGFloat(cg_image_prev!.width))
                                        }
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
                            Image(decorative: cg_image_next!, scale: 1.0)
                                .resizable()
                                .blur(radius: power_blur_radius, opaque: true)
                                .clipped()
                                .aspectRatio(contentMode: .fit).opacity(Double(image_update_ratio))
                                .overlay {
                                    GeometryReader { geom in
                                        Image(decorative: IDWImage.getScaleImage(height: 60)!, scale: 1.0).resizable().frame(width: SCALE_WIDTH)
                                        
                                        
                                        if model.max_scale != 0 {
                                            let foo: Float = speed / model.max_scale * (Float(cg_image_next!.height) - 1.0)
                                            let bar = CGFloat(foo)
                                            
                                            Image(systemName: "restart")
                                                .position(x: SCALE_WIDTH, y: speed <= model.max_scale ? geom.size.height - bar * geom.size.width / CGFloat(cg_image_next!.width) : 0)
                                            
                                            let foo2 = speed <= model.max_scale ? geom.size.height - bar * geom.size.width / CGFloat(cg_image_next!.width) + 3 : 0
                                            
                                            Text("\(UInt64(speed)) bit/s").font(.system(size: 8).monospacedDigit())
                                            //.frame(maxWidth: .infinity, alignment: .trailing)
                                                .position(x: SCALE_WIDTH + 50, y: foo2)
                                            
                                            if foo2 >= 20 {
                                                Image(systemName: "restart")
                                                    .position(x: SCALE_WIDTH, y: 0)
                                                Text("\(UInt64(model.max_scale)) bit/s").font(.system(size: 8).monospacedDigit())
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
                                            if idw_transient_value != nil {
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
                                                    idw_transient_value = IDWValue(x: last_loc_x!, y: last_loc_y!, v: speed, type: idw_transient_value!.type)
                                                    updateMap(debug_x: last_loc_x, debug_y: last_loc_y)
                                                } else {
                                                    let foo = model.max_scale * Float(last_loc_y!) / Float(model.input_map_image!.cgImage!.height)
                                                    let val = IDWValue<Float>(x: idw_transient_value!.x, y: idw_transient_value!.y, v: foo, type: idw_transient_value!.type)
                                                    model.idw_values.append(val)
                                                    idw_transient_value = nil
                                                }
                                            }
                                        }
                                )
                        }
                    }
                }
                
                if ENABLE_DEBUG_INTERFACE {
                    HStack {
                        VStack {
                            Toggle(isOn: $toggle_help) {
                                Text("help").font(.footnote).foregroundColor(Color(COLORS.standard_background)).frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            Toggle(isOn: $toggle_preview) {
                                Text("ignore white AP").font(.footnote).foregroundColor(Color(COLORS.standard_background)).frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }.fixedSize()
                        Spacer(minLength: 30)
                        VStack {
                            HStack {
                                Image(systemName: "checkerboard.rectangle").foregroundColor(Color(COLORS.standard_background))
                                Slider(value: $power_scale, in: 0...POWER_SCALE_MAX)
                            }
                            HStack {
                                Image(systemName: "slowmo").foregroundColor(Color(COLORS.standard_background))
                                Slider(value: $power_scale_radius, in: 1...POWER_SCALE_RADIUS_MAX)
                            }
                        }
                    }.padding()
                    
                    Slider(value: $power_blur_radius, in: 1...POWER_BLUR_RADIUS_MAX)
                }
                
                Spacer()
                HStack {
                    EmptyView().onReceive(timer_set_speed) { _ in // 100 Hz
                        // Manage speed
                        let interval_speed = Float(Date().timeIntervalSince(self.average_last_update))
                        let UPDATE_SPEED_DELAY: Float = 1.0
                        if interval_speed < UPDATE_SPEED_DELAY {
                            speed = average_prev * (UPDATE_SPEED_DELAY - interval_speed) / UPDATE_SPEED_DELAY + average_next * interval_speed / UPDATE_SPEED_DELAY
                            if speed > model.max_scale { model.max_scale = speed }
                        } else {
                            speed = average_next
                            if speed > model.max_scale { model.max_scale = speed }
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
                            if idw_transient_value != nil {
                                idw_transient_value = IDWValue(x: idw_transient_value!.x, y: idw_transient_value!.y, v: speed, type: idw_transient_value!.type)
                            }
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
