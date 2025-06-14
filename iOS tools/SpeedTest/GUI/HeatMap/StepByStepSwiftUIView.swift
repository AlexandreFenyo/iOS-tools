//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

// Credits for images: https://www.freepik.com/free-vector/remote-management-teamwork-isometric-icons-set-with-employees-working-computers-from-home-isolated-vector-illustration_26762614.htm
// made by https://www.freepik.com/author/macrovector

// Dans l'ordre :
// StepWelcomeView: propose 3 choix: advanced gui, step by step mode, doc
//   StepFloorPlan: propose de choisir un floor plan parmi 6

import PhotosUI
import SpriteKit
import StoreKit
import SwiftUI
import iOSToolsMacros
import UIKit

public var step_by_step_exporting_map = false

public class StepByStepViewModel : ObservableObject {
    static let shared = StepByStepViewModel()
    @Published var input_map_image: UIImage? = nil
    @Published var original_map_image: UIImage? = nil
    @Published var original_map_image_rotation: Bool? = nil
    @Published var idw_values = Array<IDWValue<Float>>()
    @Published var step = 0
    @Published var max_scale: Float = LOWEST_MAX_SCALE

    func max_value() -> Float {
       return idw_values.max(by: { $0.v < $1.v })?.v ?? 0
   }
}

enum NavigationTarget: Hashable {
    case step_choose_plan
    case step_heat_map
}

// faire descendre le max_scale s’il est supérieur au max des mesures aux endroits choisis

@MainActor
class StepByStepPhotoController: NSObject {
    weak var step_by_step_view_controller: StepByStepViewController?
    
    public init(step_by_step_view_controller: StepByStepViewController) {
        self.step_by_step_view_controller = step_by_step_view_controller
    }
    
    @objc private func image(_ image: UIImage,
                             didFinishPhotoLibrarySavingWithError error: Error?,
                             contextInfo: UnsafeRawPointer) {
        //        print("Image successfully written to camera roll")
        exporting_map = false
        if error != nil {
            popUp(NSLocalizedString("Error saving map", comment: "Error saving map"), NSLocalizedString("Access to photos is forbidden. You need to change the access rights in the app configuration panel (click on the wheel button in the toolbar to access the configuration panel)", comment: "Access to photos is forbidden. You need to change the access rights in the app configuration panel (click on the wheel button in the toolbar to access the configuration panel)"), "OK")
        } else {
            popUp(NSLocalizedString("Map saved", comment: "Map saved"), NSLocalizedString("You can find the heatmap in you photo roll", comment: "You can find the heatmap in you photo roll"), "OK")
        }
    }
    
    public func popUp(_ title: String, _ message: String, _ ok: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: ok, style: .default) {_ in
            SKStoreReviewController.requestReview()
        }
        alert.addAction(action)
        self.step_by_step_view_controller?.present(alert, animated: true)
    }
    
    public func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishPhotoLibrarySavingWithError:contextInfo:)), nil)
    }
}

@MainActor
struct StepByStepSwiftUIView: View {
    @State private var showing_exit_popup = false
    @State private var showing_doc_popup = false
    @State private var showing_doc_popup2 = false
    @State private var showing_doc_popup3 = false
    @State private var showing_exit_button = false
    @State private var scale: CGFloat = 0.0
    @State private var navigation_path = NavigationPath()

    @ObservedObject var model = StepByStepViewModel.shared

    weak var step_by_step_view_controller: StepByStepViewController?

    init(_ step_by_step_view_controller: StepByStepViewController) {
        self.step_by_step_view_controller = step_by_step_view_controller
    }

    public func cleanUp() {
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Text("WiFi Heatmap & Network Tools")
                    .font(Font.system(size: 14, weight: .bold).lowercaseSmallCaps())
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding(.vertical)

                Spacer()
            }.background(Color(COLORS.toolbar_background))

            // NavigationStack root screen: StepWelcomeView
            NavigationStack(path: $navigation_path) {
                StepWelcomeView(showing_exit_button: $showing_exit_button, showing_exit_popup: $showing_exit_popup, showing_doc_popup: $showing_doc_popup, showing_doc_popup2: $showing_doc_popup2, showing_doc_popup3: $showing_doc_popup3, scale: $scale, navigation_path: $navigation_path, model: model, step_by_step_view_controller: step_by_step_view_controller)
            }
            .background(Color(COLORS.right_pannel_scroll_bg))
            .cornerRadius(15)

            if showing_exit_button {
                HStack {
                    Spacer()

                    Button("Advanced Interface") {
                        showing_exit_popup = true
                    }
                    .font(Font.system(size: 14, weight: .bold).lowercaseSmallCaps())
                    .opacity(scale)
                    .padding(0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            scale = 1
                        }
                    }

                    Spacer()

                    Button("Web Site") {
                        UIApplication.shared.open(URL(string: "https://fenyo.net/network3dwifitools/new-manual.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))")!)
                    }
                    .font(Font.system(size: 14, weight: .bold).lowercaseSmallCaps())
                    .opacity(scale)
                    .padding(0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            scale = 1
                        }
                    }

                    Spacer()
                }
            } else {
                Button("") {}
                    .opacity(0)
                    .padding(0)

                Button("") {}
                    .opacity(0)
                    .padding(0)
            }

            if UIDevice.current.userInterfaceIdiom != .pad
                && ProcessInfo.processInfo.isMacCatalystApp == false && showing_exit_button == false {
                Text("Click on your prefered blinking rectangle to choose between advanced interface, step-by-step heatmap and documentation. Click on the question marks to get help about each interface.")
                    .font(.custom("Verdana", size: 12))
                    .foregroundColor(.gray.darker())
                    .multilineTextAlignment(.center).padding()
            }
        }
        .padding(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
        .background(Color(COLORS.right_pannel_bg))
        .sheet(
            isPresented: $showing_exit_popup,
            content: {
                ModalPopPupShell(
                    action: {
                        step_by_step_view_controller?.dismiss(animated: true)
                    },
                    NSLocalizedString(
                        "Open Advanced Interface",
                        comment: "Returning To The App Home Page"),
                    NSLocalizedString("OPEN ADVANCED INTERFACE", comment: "OPEN ADVANCED INTERFACE"),
                    {
                        Text("")
                        Text("You will be able to come back later to the home window simply by clicking on the following icon:")
                        
                        Image(systemName: "house")
                            .scaleEffect(2)
                            .padding(10)
                        
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            Spacer()
                            /*
                            // We run on an iPad or a Mac
                            LandscapePortraitView {
                                Image("design-manual").resizable().aspectRatio(
                                    contentMode: .fit
                                ).padding(10)
                                
                                Image("design-auto").resizable().aspectRatio(
                                    contentMode: .fit
                                ).padding(10)
                                
                                Image("design-doc").resizable().aspectRatio(
                                    contentMode: .fit
                                ).padding(10)
                            }
                             */
                        }
                        
                        Text("")
                    }
                )
            }
        )
        
        // iPhone only (showing_doc_popup is always false on iPad or macOS)
        .sheet(isPresented: $showing_doc_popup,
            content: {
                ModalPopPupShellDoc(
                    {
                        Text("The advanced interface provides access to every network tools (discovery of devices on the local network, latency and throughput measurements, scanning of open ports and services, 3D view of the network, ...).\n\nIt also allows building a WiFi coverage heatmap, with many options. This interface is intended for users who already have some initial knowledge of networks.")
                            .font(.custom("Verdana", size: 13))
                            .foregroundColor(.gray.darker())
                            .multilineTextAlignment(.leading).padding()
                    }
                )
            }
        )
        .sheet(isPresented: $showing_doc_popup2,
            content: {
                ModalPopPupShellDoc(
                    {
                        Text("The step-by-step interface is dedicated to building a WiFi coverage heatmap, it is specifically aimed at users wishing to create a WiFi coverage heatmap as simply as possible, with complete support.\n\nNo prior knowledge of networks is necessary.")
                            .font(.custom("Verdana", size: 13))
                            .foregroundColor(.gray.darker())
                            .multilineTextAlignment(.leading).padding()
                    }
                )
            }
        )
        .sheet(isPresented: $showing_doc_popup3,
            content: {
                ModalPopPupShellDoc(
                    {
                        Text("The documentation describes the steps to build a WiFi coverage heatmap with the advanced interface, using for example two iPhone/iPad to establish local measurements, or using a single iPhone/iPad and the CHARGEN (traffic generation protocol) responder deployed on the Internet and dedicated to this application.\n\nTo discover the other tools provided by this application (discovery of devices on the local network, latency and throughput measurements, scanning of open ports and services, 3D view of the network, ...) launch the advanced interface and click on the help button at the top left of the screen.")
                            .font(.custom("Verdana", size: 13))
                            .foregroundColor(.gray.darker())
                            .multilineTextAlignment(.leading).padding()
                    }
                )
            }
        )

    }
}

struct StepWelcomeView: View {
    @Binding var showing_exit_button: Bool
    @Binding var showing_exit_popup: Bool
    @Binding var showing_doc_popup: Bool
    @Binding var showing_doc_popup2: Bool
    @Binding var showing_doc_popup3: Bool
    @Binding var scale: CGFloat
    @Binding var navigation_path: NavigationPath

    @ObservedObject var model: StepByStepViewModel

    weak var step_by_step_view_controller: StepByStepViewController?

    let padding_size: CGFloat = 10

    var body: some View {
        VStack(alignment: .center) {
            LandscapePortraitView {
                Button(action: {
                    showing_exit_popup = true
                }) {
                    BlinkingContent {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Open advanced interface")
                                    .font(.custom("Verdana", size: 15)).bold()
                                    .foregroundColor(.gray.darker())

                                if (ProcessInfo.processInfo.isMacCatalystApp || UIDevice.current.userInterfaceIdiom == .pad) {
                                    Text("The advanced interface provides access to every network tools (discovery of devices on the local network, latency and throughput measurements, scanning of open ports and services, 3D view of the network, ...).\n\nIt also allows building a WiFi coverage heatmap, with many options. This interface is intended for users who already have some initial knowledge of networks.")
                                        .font(.custom("Verdana", size: 13))
                                        .foregroundColor(.gray.darker())
                                        .multilineTextAlignment(.leading).padding()
                                }

                                Spacer()

                                HStack {
                                    Spacer()
                                    Image("design-manual").resizable().aspectRatio(contentMode: .fit)
                                        .padding(padding_size)
                                    Spacer()

                                    if (ProcessInfo.processInfo.isMacCatalystApp == false && UIDevice.current.userInterfaceIdiom != .pad) {
                                        Button(action: {
                                            showing_doc_popup = true
                                        }) {
                                            Image(systemName: "questionmark.circle.fill").scaleEffect(2).padding().opacity(0.7)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }.background(.white)
                    }.padding(padding_size)
                }

                Button(action: {
                    navigation_path.append(NavigationTarget.step_choose_plan)
                }) {
                    BlinkingContent {
                        HStack {
                            Spacer()
                            VStack {
                                if ProcessInfo.processInfo.isMacCatalystApp || UIDevice.current.userInterfaceIdiom == .pad {
                                    Text("Step-by-step easy mode")
                                        .font(.custom("Verdana", size: 15)).bold()
                                        .foregroundColor(.gray.darker())
                                } else {
                                    Text("Step-by-step easy mode (heatmap only)")
                                        .font(.custom("Verdana", size: 15)).bold()
                                        .foregroundColor(.gray.darker())
                                }

                                if ProcessInfo.processInfo.isMacCatalystApp || UIDevice.current.userInterfaceIdiom == .pad {
                                    Text("The step-by-step interface is dedicated to building a WiFi coverage heatmap, it is specifically aimed at users wishing to create a WiFi coverage heatmap as simply as possible, with complete support.\n\nNo prior knowledge of networks is necessary.")
                                        .font(.custom("Verdana", size: 13))
                                        .foregroundColor(.gray.darker())
                                        .multilineTextAlignment(.leading).padding()
                                }

                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    Image("design-auto").resizable().aspectRatio(contentMode: .fit)
                                        .padding(padding_size)
                                    Spacer()

                                    if (ProcessInfo.processInfo.isMacCatalystApp == false && UIDevice.current.userInterfaceIdiom != .pad) {
                                        Button(action: {
                                            showing_doc_popup2 = true
                                        }) {
                                            Image(systemName: "questionmark.circle.fill").scaleEffect(2).padding().opacity(0.7)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }.background(.white)
                    }.padding(padding_size)
                }.navigationDestination(for: NavigationTarget.self) { target in
                    switch target {
                    case .step_choose_plan:
                        VStack {
                            Text("Choose a predefined floor plan or load an image")
                                .font(.custom("Verdana", size: 15)).bold()
                                .foregroundColor(.gray.darker())

                            OrientationView { is_portrait, size in
                                StepChoosePlan(navigation_path: $navigation_path, model: model, step_by_step_view_controller: step_by_step_view_controller, is_portrait: is_portrait, size: size)
                                    .onAppear {
                                        showing_exit_button = true
                                    }
                            }
                        }.background(Color(COLORS.right_pannel_scroll_bg))
                        
                    case .step_heat_map:
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller)
                    }
                }

                NavigationLink {
                    StepDocumentation().onAppear {
                        showing_exit_button = true
                    }
                } label: {
                    BlinkingContent {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Documentation")
                                    .font(.custom("Verdana", size: 15)).bold()
                                    .foregroundColor(.gray.darker())
                                
                                if ProcessInfo.processInfo.isMacCatalystApp || UIDevice.current.userInterfaceIdiom == .pad {
                                    Text("The documentation describes the steps to build a WiFi coverage heatmap with the advanced interface, using for example two iPhone/iPad to establish local measurements, or using a single iPhone/iPad and the CHARGEN (traffic generation protocol) responder deployed on the Internet and dedicated to this application.\n\nTo discover the other tools provided by this application (discovery of devices on the local network, latency and throughput measurements, scanning of open ports and services, 3D view of the network, ...) launch the advanced interface and click on the help button at the top left of the screen.")
                                        .font(.custom("Verdana", size: 13))
                                        .foregroundColor(.gray.darker())
                                        .multilineTextAlignment(.leading).padding()
                                }

                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    Image("design-doc").resizable().aspectRatio(contentMode: .fit)
                                        .padding(padding_size)
                                    Spacer()

                                    if (ProcessInfo.processInfo.isMacCatalystApp == false && UIDevice.current.userInterfaceIdiom != .pad) {
                                        Button(action: {
                                            showing_doc_popup3 = true
                                        }) {
                                            Image(systemName: "questionmark.circle.fill").scaleEffect(2).padding().opacity(0.7)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }.background(.white)
                    }.padding(padding_size)
                }.onAppear {
                    scale = 0
                    showing_exit_button = false
                }
            }
            .background(Color(COLORS.right_pannel_scroll_bg))
        }
    }
}

struct StepHeatMap: View {
    static let MAX_SIZE = 600
    
    @ObservedObject var model: StepByStepViewModel
    
    @Binding var navigation_path: NavigationPath
    
    weak var step_by_step_view_controller: StepByStepViewController?
    var image_name: String?

    static func rotateIfNeeded(_ img: UIImage) -> UIImage {
        if img.cgImage!.width < img.cgImage!.height {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: img.cgImage!.height, height: img.cgImage!.width))
            let image = renderer.image { _ in
                let context = UIGraphicsGetCurrentContext()
                context?.rotate(by: Double.pi / 2)
                context?.draw(img.cgImage!, in: CGRect(origin: CGPoint(x: 0, y: -img.cgImage!.height), size: CGSize(width: img.cgImage!.width, height: img.cgImage!.height)))
            }
            return image.withHorizontallyFlippedOrientation()
        }
        return img
    }

    static func resizeIfNeeded(_ img: UIImage) -> UIImage {
        if img.cgImage!.width > MAX_SIZE || img.cgImage!.height > MAX_SIZE {
            let size: CGSize
            if img.cgImage!.width > img.cgImage!.height {
                size = CGSize(width: MAX_SIZE, height: img.cgImage!.height * MAX_SIZE / img.cgImage!.width)
            } else {
                size = CGSize(width: img.cgImage!.width * MAX_SIZE / img.cgImage!.height, height: MAX_SIZE)
            }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                img.draw(in: CGRect(origin: .zero, size: size))
            }
            return image
        }
        return img
    }

    var body: some View {
        StepByStepHeatMapView(step_by_step_view_controller!)
            .onAppear {
                Task {
                    await step_by_step_view_controller?.master_view_controller?.chargenTCP(IPv4Address("51.75.31.39")!)
                }
                
                if let image_name {
                    let image = UIImage(named: image_name)
                    let resized_image = StepHeatMap.resizeIfNeeded(StepHeatMap.rotateIfNeeded(image!))
                    model.original_map_image_rotation = (image!).cgImage!.width < (image!).cgImage!.height
                    model.original_map_image = StepHeatMap.rotateIfNeeded(image!)
                    model.input_map_image = resized_image
                    model.idw_values = Array<IDWValue>()
                    
                    // Initialize other model parameters
                    model.step = 0
                    model.max_scale = LOWEST_MAX_SCALE
                }
            }
    }
}

struct StepChoosePlan: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showing_map_picker = false
    @State private var showing_alert = false

    @Binding var navigation_path: NavigationPath

    @ObservedObject var model: StepByStepViewModel

    weak var step_by_step_view_controller: StepByStepViewController?

    var is_portrait: Bool
    var size: CGSize

    var body: some View {
        VStack(alignment: .center) {
            if is_portrait {
                HStack(alignment: .center) {
                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-rectangle")
                    } label: {
                        BlinkingContent {
                            Image("plan-rectangle").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-T")
                    } label: {
                        BlinkingContent {
                            Image("plan-T").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()
                }

                HStack(alignment: .center) {
                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-2rect")
                    } label: {
                        BlinkingContent {
                            Image("plan-2rect").resizable().aspectRatio(contentMode: .fit)
                        }
                    }
                    
                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-thin")
                    } label: {
                        BlinkingContent {
                            Image("plan-thin").resizable().aspectRatio(contentMode: .fit)
                        }
                    }
                    
                    Spacer()
                }
                
                HStack(alignment: .center) {
                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-bgonly")
                    } label: {
                        BlinkingContent {
                            Image("plan-bgonly").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    Button(action: {
                        showing_map_picker = true
                    }) {
                        BlinkingContent {
                            ZStack {
                                Image("plan-empty").resizable().aspectRatio(contentMode: .fit)
                                Image(systemName: "photo.badge.plus").scaleEffect(2).opacity(0.5)
                            }
                        }
                    }

                    Spacer()
                }
            } else {
                HStack(alignment: .center) {
                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-rectangle")
                    } label: {
                        BlinkingContent {
                            Image("plan-rectangle").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-T")
                    } label: {
                        BlinkingContent {
                            Image("plan-T").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-2rect")
                    } label: {
                        BlinkingContent {
                            Image("plan-2rect").resizable().aspectRatio(contentMode: .fit)
                        }
                    }
                    
                    Spacer()
                }
                
                HStack(alignment: .center) {
                    Spacer()
                    
                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-thin")
                    } label: {
                        BlinkingContent {
                            Image("plan-thin").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(model: model, navigation_path: $navigation_path, step_by_step_view_controller: step_by_step_view_controller, image_name: "plan-bgonly")
                    } label: {
                        BlinkingContent {
                            Image("plan-bgonly").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()
                    
                    Button(action: {
                        showing_map_picker = true
                    }) {
                        BlinkingContent {
                            ZStack {
                                Image("plan-empty").resizable().aspectRatio(contentMode: .fit)
                                Image(systemName: "photo.badge.plus").scaleEffect(2).opacity(0.5)
                            }
                        }
                    }
                    Spacer()
                }
            }
        }.padding()
            .sheet(isPresented: $showing_map_picker, onDismiss: {() -> Void in
                if model.original_map_image_rotation == true {
                    showing_alert = true
                }
            }) {
                ImagePicker(image: $model.input_map_image, original_map_image: $model.original_map_image, original_map_image_rotation: $model.original_map_image_rotation, idw_values: $model.idw_values, when_done: {
                    navigation_path.append(NavigationTarget.step_heat_map)
                })
            }
        
            .sheet(isPresented: $showing_alert) {
                VStack {
                    Text("Image rotation applied")
                        .font(.title)
                        .padding(20)
                    Spacer()
                    Text("The floor plan you selected is not in portrait mode. Therefore a rotation has been applied to the picture. At the end of the heat map building process, when you will tap on Share your map, the heat map will be saved in the original vertical mode in your photo roll.")
                        .font(.caption)
                    Image(uiImage: model.input_map_image!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: horizontalSizeClass != .compact ? 400 : 200)
                        .padding(5)
                    Spacer()
                    Button("Continue",
                           action: { showing_alert.toggle() })
                    .padding(20)
                }.background(Color(COLORS.right_pannel_scroll_bg))
            }
    }
}

struct StepDocumentation: View {
    var body: some View {
        WebContent(
            url:
                "https://fenyo.net/network3dwifitools/new-manual.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))"
        )
        .padding(20)
    }
}

