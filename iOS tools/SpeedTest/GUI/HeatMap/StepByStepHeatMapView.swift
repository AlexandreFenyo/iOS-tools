//
//  StepByStepHeatMapView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 23/10/2024.
//  Copyright © 2024 Alexandre Fenyo. All rights reserved.
//

import Foundation
import PhotosUI
import SpriteKit
import StoreKit
import SwiftUI
import iOSToolsMacros

private let NEW_PROBE_X: UInt16 = 100
private let NEW_PROBE_Y: UInt16 = 50
private let NEW_PROBE_VALUE: Float = 10_000_000
private let SCALE_WIDTH: CGFloat = 30
private let POWER_SCALE_DEFAULT: Float = 5
private let POWER_SCALE_MAX: Float = 5
private let POWER_SCALE_RADIUS_MAX: Float = 600
private let POWER_SCALE_RADIUS_DEFAULT: Float = 120 /* 180 */
private let POWER_BLUR_RADIUS_DEFAULT: CGFloat = 10
private let POWER_BLUR_RADIUS_MAX: CGFloat = 20

@MainActor
struct StepByStepHeatMapView: View {
    init(_ step_by_step_view_controller: StepByStepViewController) {
        self.step_by_step_view_controller = step_by_step_view_controller
        self.photoController = StepByStepPhotoController(
            step_by_step_view_controller: step_by_step_view_controller)
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    fileprivate let photoController: StepByStepPhotoController
    weak var step_by_step_view_controller: StepByStepViewController?

    @ObservedObject var model = StepByStepViewModel.shared
    @State private var showing_map_picker = false
    @State private var showing_alert = false
    @State private var showing_progress = false

    @State private var average_last_update = Date()
    @State private var average_prev: Float = 0
    @State private var average_next: Float = 0

    @State private var image_last_update = Date()
    @State private var cg_image_prev: CGImage?
    @State private var cg_image_next: CGImage?
    @State private var image_update_ratio: Float = 0

    @State private var last_loc_x: UInt16?
    @State private var last_loc_y: UInt16?

    @State private var idw_transient_value: IDWValue<Float>?  // = IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)

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

    let timer_get_average = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
    let timer_set_speed = Timer.publish(every: 0.01, on: .main, in: .common)
        .autoconnect()
    let timer_create_map = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()

    public func cleanUp() {
    }

    private func updateSteps() {
        if model.input_map_image == nil {
            model.step = 0
        } else {
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
        if exporting_map == true { return }

        let width = UInt16(model.input_map_image!.cgImage!.width)
        let height = UInt16(model.input_map_image!.cgImage!.height)
        var idw_image = IDWImage(width: width, height: height)
        let transient_set: Set<IDWValue<Float>> =
            (!toggle_preview && idw_transient_value != nil)
            ? Set([idw_transient_value!]) : Set()

        // on prend toute la plage disponible pour les valeurs des mesures qu'on prend en compte
        let max = model.max_scale

        if max != 0 {
            let values = Set(model.idw_values).union(transient_set).map {
                IDWValue<UInt16>(
                    x: $0.x, y: $0.y,
                    v: UInt16($0.v / max * Float(UInt16.max - 1)))
            }
            _ = values.map { idw_image.addValue($0) }
        }

        Task {
            let new_vertices = idw_image.getValues().map {
                CGPoint(x: Double($0.x), y: Double($0.y))
            }

            let need_update_cache =
                distance_cache == nil
                || Set(new_vertices) != Set(distance_cache!.vertices)
            cg_image_prev = cg_image_next

            var new_distance_cache: DistanceCache?
            (cg_image_next, new_distance_cache) =
                await idw_image.computeCGImageAsync(
                    power_scale: power_scale,
                    power_scale_radius: toggle_radius ? power_scale_radius : 0,
                    debug_x: debug_x, debug_y: debug_y,
                    distance_cache: need_update_cache ? nil : distance_cache)
            if let new_distance_cache {
                distance_cache = new_distance_cache
            }
            image_last_update = Date()
            image_update_ratio = 0
        }
    }

    var body: some View {
        LoadingView(showing_progress: $showing_progress) {
            VStack {
                VStack {
                    HStack {
                        HStack(alignment: .top) {
                            Button {
                                showing_map_picker = true
                            } label: {
                                VStack {
                                    Image(systemName: "map").resizable().frame(
                                        width: 30, height: 30)
                                    Text("Select your floor plan").font(
                                        .footnote
                                    ).frame(maxWidth: 200)
                                }
                            }
                            .disabled(model.input_map_image != nil)
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200)

                            Button {
                                idw_transient_value = IDWValue<Float>(
                                    x: NEW_PROBE_X, y: NEW_PROBE_Y,
                                    v: NEW_PROBE_VALUE, type: .ap)
                            } label: {
                                VStack {
                                    Image(
                                        systemName:
                                            "antenna.radiowaves.left.and.right"
                                    ).resizable().frame(width: 35, height: 30)
                                    Text("Add new probe").font(.footnote)
                                }
                            }
                            .disabled(
                                model.input_map_image == nil
                                    || idw_transient_value != nil
                            )
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200)

                            Button {
                                if model.idw_values.contains(
                                    idw_transient_value!) == false
                                {
                                    model.idw_values.append(
                                        idw_transient_value!)
                                    idw_transient_value = nil
                                }
                            } label: {
                                VStack {
                                    Image(
                                        systemName:
                                            "dot.radiowaves.left.and.right"
                                    ).resizable().frame(width: 35, height: 30)
                                    Text("Save measure").font(.footnote)
                                }
                            }
                            .disabled(
                                model.input_map_image == nil
                                    || idw_transient_value == nil
                                    || (idw_transient_value?.x == NEW_PROBE_X
                                        && idw_transient_value?.y == NEW_PROBE_Y)
                            )
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
                                    Image(
                                        systemName:
                                            "antenna.radiowaves.left.and.right.slash"
                                    ).resizable().frame(width: 30, height: 30)
                                    Text("Undo").font(.footnote)
                                }
                            }
                            .disabled(
                                model.input_map_image == nil
                                    || model.idw_values.count == 0
                            )
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200)

                            Button {
                                model.input_map_image = nil
                                model.idw_values = [IDWValue]()
                                distance_cache = nil
                                model.max_scale = LOWEST_MAX_SCALE
                                power_scale = POWER_SCALE_DEFAULT
                                power_scale_radius = POWER_SCALE_RADIUS_DEFAULT
                                toggle_help = false
                                toggle_preview = false
                                idw_transient_value = nil  // IDWValue<Float>(x: NEW_PROBE_X, y: NEW_PROBE_Y, v: NEW_PROBE_VALUE, type: .ap)
                                updateSteps()
                            } label: {
                                VStack {
                                    Image(systemName: "trash").resizable()
                                        .frame(width: 30, height: 30)
                                    Text("Reset all").font(.footnote)
                                }
                            }
                            .disabled(model.input_map_image == nil)
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200)

                            Button {
                                if model.original_map_image == nil
                                    || model.max_scale == 0
                                {
                                    return
                                }

                                showing_progress.toggle()
                                exporting_map = true

                                let image = model.original_map_image!
                                let image_rotation = model
                                    .original_map_image_rotation!
                                let width = image.cgImage!.width
                                let height = image.cgImage!.height
                                let screen_width = model.input_map_image?
                                    .cgImage!.width
                                let screen_height = model.input_map_image?
                                    .cgImage!.height
                                let factor_x =
                                    Float(width) / Float(screen_width!)
                                let factor_y =
                                    Float(height) / Float(screen_height!)
                                var idw_image = IDWImage(
                                    width: UInt16(width), height: UInt16(height)
                                )
                                let max = model.max_scale
                                let values = Set(model.idw_values).map {
                                    IDWValue<UInt16>(
                                        x: UInt16(Float($0.x) * factor_x),
                                        y: UInt16(Float($0.y) * factor_y),
                                        v: UInt16(
                                            $0.v / max * Float(UInt16.max - 1)))
                                }
                                _ = values.map { idw_image.addValue($0) }

                                Task {
                                    let (cg_image, _) =
                                        await idw_image.computeCGImageAsync(
                                            power_scale: power_scale,
                                            power_scale_radius:
                                                power_scale_radius * factor_x,
                                            distance_cache: nil)

                                    let ci_image_map = CIImage(
                                        cgImage: cg_image!)
                                    let ci_image_map_ext = ci_image_map.extent
                                    let ci_image_clamped =
                                        ci_image_map.clampedToExtent()
                                    let ci_context_blur = CIContext()
                                    let blur = CIFilter(name: "CIGaussianBlur")!
                                    blur.setValue(
                                        ci_image_clamped,
                                        forKey: kCIInputImageKey)
                                    blur.setValue(
                                        power_blur_radius * CGFloat(factor_x),
                                        forKey: kCIInputRadiusKey)
                                    let blurred_image = blur.outputImage
                                    let new_blur_cg_image =
                                        ci_context_blur.createCGImage(
                                            blurred_image!,
                                            from: ci_image_map_ext)
                                    let blur_image = UIImage(
                                        cgImage: new_blur_cg_image!)
                                    let ci_image_original = CIImage(
                                        cgImage: image.cgImage!)
                                    let ci_image_original_ext =
                                        ci_image_original.extent
                                    let ci_context_grayscale = CIContext()
                                    let grayscale = CIFilter(
                                        name: "CIPhotoEffectNoir")!
                                    grayscale.setValue(
                                        ci_image_original,
                                        forKey: kCIInputImageKey)
                                    var gray_image = grayscale.outputImage

                                    if image_rotation {
                                        gray_image = gray_image?.oriented(
                                            CGImagePropertyOrientation
                                                .upMirrored)
                                    }

                                    let new_grayscale_cg_image =
                                        ci_context_grayscale.createCGImage(
                                            gray_image!,
                                            from: ci_image_original_ext)
                                    let grayscale_image = UIImage(
                                        cgImage: new_grayscale_cg_image!)

                                    let size = CGSize(
                                        width: cg_image!.width,
                                        height: cg_image!.height)
                                    UIGraphicsBeginImageContext(size)
                                    let area_size = CGRect(
                                        x: 0, y: 0, width: size.width,
                                        height: size.height)
                                    blur_image.draw(
                                        in: area_size, blendMode: .normal,
                                        alpha: 1.0)
                                    grayscale_image.draw(
                                        in: area_size, blendMode: .normal,
                                        alpha: 0.2)
                                    let merged_image =
                                        UIGraphicsGetImageFromCurrentImageContext()!
                                    UIGraphicsEndImageContext()

                                    photoController.saveImage(
                                        image: merged_image)
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .resizable().frame(
                                            width: 30, height: 30)
                                    Text("Share your map").font(.footnote)
                                }
                            }
                            .disabled(
                                model.input_map_image == nil
                                    || idw_transient_value != nil
                                    || model.idw_values.count < 3
                            )
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200)

                            Button {
                                UIApplication.shared.open(
                                    URL(
                                        string:
                                            "http://wifimapexplorer.com/new-manual.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))"
                                    )!)
                            } label: {
                                VStack {
                                    Image(systemName: "questionmark")
                                        .resizable().frame(
                                            width: 20, height: 30)
                                    Text("Help").font(.footnote)
                                }
                            }
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200)

                        }.padding(.top)
                    }

                    if model.input_map_image != nil {
                        ZStack {
                            if cg_image_prev != nil {
                                Image(decorative: cg_image_prev!, scale: 1.0)
                                    .resizable()
                                    .blur(
                                        radius: power_blur_radius, opaque: true
                                    )
                                    .clipped()
                                    .aspectRatio(contentMode: .fit)
                                    .overlay {
                                        GeometryReader { geom in
                                            if idw_transient_value != nil {
                                                Image(
                                                    systemName:
                                                        "dot.radiowaves.left.and.right"
                                                )
                                                .resizable().frame(
                                                    width: 40, height: 30
                                                )
                                                .colorInvert()
                                                .position(
                                                    x: CGFloat(
                                                        idw_transient_value!.x)
                                                        * geom.size.width
                                                        / CGFloat(
                                                            cg_image_prev!.width
                                                        ),
                                                    y: geom.size.height
                                                        - CGFloat(
                                                            idw_transient_value!
                                                                .y)
                                                        * geom.size.width
                                                        / CGFloat(
                                                            cg_image_prev!.width
                                                        ))
                                            }
                                            // 256 probes displayed at max
                                            let values = model.idw_values.sorted
                                            {
                                                $0.x == $1.x
                                                    ? $0.y < $1.y : $0.x < $0.y
                                            }
                                            ForEach(0..<256) { index in
                                                if index < values.count {
                                                    let idw_value: IDWValue =
                                                        values[index]
                                                    Image(
                                                        systemName: idw_value
                                                            .type == .ap
                                                            ? "antenna.radiowaves.left.and.right"
                                                            : "dot.radiowaves.left.and.right"
                                                    )
                                                    .position(
                                                        x: CGFloat(idw_value.x)
                                                            * geom.size.width
                                                            / CGFloat(
                                                                cg_image_prev!
                                                                    .width),
                                                        y: geom.size.height
                                                            - CGFloat(
                                                                idw_value.y)
                                                            * geom.size.width
                                                            / CGFloat(
                                                                cg_image_prev!
                                                                    .width))
                                                }
                                            }
                                        }
                                    }
                            }

                            if cg_image_next != nil {
                                Image(decorative: cg_image_next!, scale: 1.0)
                                    .resizable()
                                    .blur(
                                        radius: power_blur_radius, opaque: true
                                    )
                                    .clipped()
                                    .aspectRatio(contentMode: .fit).opacity(
                                        Double(image_update_ratio)
                                    )
                                    .overlay {
                                        GeometryReader { geom in
                                            Image(
                                                decorative:
                                                    IDWImage.getScaleImage(
                                                        height: 60)!, scale: 1.0
                                            ).resizable().frame(
                                                width: SCALE_WIDTH)

                                            if model.max_scale != 0 {
                                                let foo: Float =
                                                    speed / model.max_scale
                                                    * (Float(
                                                        cg_image_next!.height)
                                                        - 1.0)
                                                let bar = CGFloat(foo)

                                                Image(systemName: "restart")
                                                    .position(
                                                        x: SCALE_WIDTH,
                                                        y: speed
                                                            <= model.max_scale
                                                            ? geom.size.height
                                                                - bar
                                                                * geom.size
                                                                .width
                                                                / CGFloat(
                                                                    cg_image_next!
                                                                        .width)
                                                            : 0)

                                                let foo2 =
                                                    speed <= model.max_scale
                                                    ? geom.size.height - bar
                                                        * geom.size.width
                                                        / CGFloat(
                                                            cg_image_next!.width
                                                        ) + 3 : 0

                                                Text("\(UInt64(speed)) bit/s")
                                                    .font(
                                                        .system(size: 8)
                                                            .monospacedDigit()
                                                    )
                                                    //.frame(maxWidth: .infinity, alignment: .trailing)
                                                    .position(
                                                        x: SCALE_WIDTH + 50,
                                                        y: foo2)

                                                if foo2 >= 20 {
                                                    Image(systemName: "restart")
                                                        .position(
                                                            x: SCALE_WIDTH, y: 0
                                                        )
                                                    Text(
                                                        "\(UInt64(model.max_scale)) bit/s"
                                                    ).font(
                                                        .system(size: 8)
                                                            .monospacedDigit()
                                                    )
                                                    .position(
                                                        x: SCALE_WIDTH + 50,
                                                        y: 0)
                                                }
                                            }
                                        }
                                    }
                            }

                            Image(uiImage: model.input_map_image!)
                                .resizable().aspectRatio(contentMode: .fit)
                                .grayscale(1.0).opacity(0.2)
                        }
                        .overlay {
                            GeometryReader { geom in
                                Rectangle().foregroundColor(.gray).opacity(0.01)
                                    .gesture(
                                        DragGesture(
                                            minimumDistance: 0,
                                            coordinateSpace: .local
                                        )
                                        .onEnded { position in
                                            if idw_transient_value != nil {
                                                let loc_screen = position
                                                    .location
                                                var xx = Int(
                                                    loc_screen.x
                                                        / geom.size.width
                                                        * Double(
                                                            model
                                                                .input_map_image!
                                                                .cgImage!.width)
                                                )
                                                var yy = Int(
                                                    (geom.size.height
                                                        - loc_screen.y)
                                                        / geom.size.height
                                                        * Double(
                                                            model
                                                                .input_map_image!
                                                                .cgImage!.height
                                                        ))
                                                if xx < 0 { xx = 0 }
                                                if yy < 0 { yy = 0 }
                                                if xx
                                                    >= model.input_map_image!
                                                    .cgImage!.width
                                                {
                                                    xx =
                                                        model.input_map_image!
                                                        .cgImage!.width - 1
                                                }
                                                if yy
                                                    >= model.input_map_image!
                                                    .cgImage!.height
                                                {
                                                    yy =
                                                        model.input_map_image!
                                                        .cgImage!.height - 1
                                                }
                                                last_loc_x = UInt16(xx)
                                                last_loc_y = UInt16(yy)

                                                let foo = CGFloat(last_loc_x!)
                                                if foo >= SCALE_WIDTH {
                                                    idw_transient_value =
                                                        IDWValue(
                                                            x: last_loc_x!,
                                                            y: last_loc_y!,
                                                            v: speed,
                                                            type:
                                                                idw_transient_value!
                                                                .type)
                                                    updateMap(
                                                        debug_x: last_loc_x,
                                                        debug_y: last_loc_y)
                                                } else {
                                                    let foo =
                                                        model.max_scale
                                                        * Float(last_loc_y!)
                                                        / Float(
                                                            model
                                                                .input_map_image!
                                                                .cgImage!.height
                                                        )
                                                    let val = IDWValue<Float>(
                                                        x: idw_transient_value!
                                                            .x,
                                                        y: idw_transient_value!
                                                            .y, v: foo,
                                                        type:
                                                            idw_transient_value!
                                                            .type)
                                                    model.idw_values.append(val)
                                                    idw_transient_value = nil
                                                }
                                            }
                                        }
                                    )
                            }
                        }
                    }

                    Spacer()
                    HStack {
                        EmptyView().onReceive(timer_set_speed) { _ in  // 100 Hz
                            // Manage speed
                            let interval_speed = Float(
                                Date().timeIntervalSince(
                                    self.average_last_update))
                            let UPDATE_SPEED_DELAY: Float = 1.0
                            if interval_speed < UPDATE_SPEED_DELAY {
                                speed =
                                    average_prev
                                    * (UPDATE_SPEED_DELAY - interval_speed)
                                    / UPDATE_SPEED_DELAY + average_next
                                    * interval_speed / UPDATE_SPEED_DELAY
                                if speed > model.max_scale {
                                    model.max_scale = speed
                                }
                            } else {
                                speed = average_next
                                if speed > model.max_scale {
                                    model.max_scale = speed
                                }
                            }

                            // Manage heat maps
                            let interval_image = Float(
                                Date().timeIntervalSince(self.image_last_update)
                            )
                            let UPDATE_IMAGE_DELAY: Float = 1.0
                            if interval_image < UPDATE_IMAGE_DELAY {
                                image_update_ratio = interval_image
                            } else {
                                image_update_ratio = 1
                            }
                        }
                        .onReceive(timer_get_average) { _ in  // 1 Hz
                            if exporting_map == false {
                                showing_progress = false
                            }

                            display_steps.toggle()
                            Task {
                                if let step_by_step_view_controller =
                                    photoController.step_by_step_view_controller
                                {
                                    average_last_update = Date()
                                    average_prev = average_next
                                    average_next = step_by_step_view_controller
                                        .master_view_controller!
                                        .detail_view_controller!.ts.getAverage()
                                    if average_prev == 0.0 {
                                        average_prev = average_next
                                    }
                                }
                            }
                        }
                        .onReceive(timer_create_map) { _ in  // 1 Hz
                            if model.input_map_image != nil {
                                if idw_transient_value != nil {
                                    idw_transient_value = IDWValue(
                                        x: idw_transient_value!.x,
                                        y: idw_transient_value!.y, v: speed,
                                        type: idw_transient_value!.type)
                                }
                                updateMap()
                            }
                        }
                    }
                }
                .background(Color(COLORS.right_pannel_scroll_bg))
                .cornerRadius(15).padding(10)
                .sheet(isPresented: $showing_alert) {
                    VStack {
                        Text("Image rotation applied")
                            .font(.title)
                            .padding(20)
                        Spacer()
                        Text(
                            "The floor plan you selected is not in portrait mode. Therefore a rotation has been applied to the picture. At the end of the heat map building process, when you will tap on Share your map, the heat map will be saved in the original vertical mode in your photo roll."
                        )
                        .font(.caption)
                        Image(uiImage: model.input_map_image!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                maxHeight: horizontalSizeClass != .compact ? 400 : 200
                            )
                            .padding(5)
                        Spacer()
                        Button(
                            "Continue",
                            action: { showing_alert.toggle() }
                        )
                        .padding(20)
                    }
                }
            }.background(Color(COLORS.right_pannel_bg))
        }
    }
}