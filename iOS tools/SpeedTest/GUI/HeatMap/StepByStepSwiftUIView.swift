//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

// Credits for images: https://www.freepik.com/free-vector/remote-management-teamwork-isometric-icons-set-with-employees-working-computers-from-home-isolated-vector-illustration_26762614.htm
// made by https://www.freepik.com/author/macrovector

import PhotosUI
import SpriteKit
import StoreKit
import SwiftUI

public var step_by_step_exporting_map = false

// sliders et toggles de réglage fin des paramètres
private var ENABLE_DEBUG_INTERFACE = false

private let NEW_PROBE_X: UInt16 = 100
private let NEW_PROBE_Y: UInt16 = 50
private let NEW_PROBE_VALUE: Float = 10_000_000
private let SCALE_WIDTH: CGFloat = 30
private let LOWEST_MAX_SCALE: Float = 1000
private let POWER_SCALE_DEFAULT: Float = 5
private let POWER_SCALE_MAX: Float = 5
private let POWER_SCALE_RADIUS_MAX: Float = 600
private let POWER_SCALE_RADIUS_DEFAULT: Float = 120 /* 180 */
private let POWER_BLUR_RADIUS_DEFAULT: CGFloat = 10
private let POWER_BLUR_RADIUS_MAX: CGFloat = 20

public class StepByStepViewModel : ObservableObject {
    static let shared = StepByStepViewModel()
    static let step2String = [
        "step 1/5: select your floor plan (click on the Select your floor plan green button)",
        NSLocalizedString("Come back here after having started a TCP Flood Chargen action on a target (download speed testing).\nThe target must remain the same until the heat map is built.\n- to estimate the Wi-Fi internal throughput between local hosts, either select a target on the local wired network, or select a wirelessly connected target that is as close as possible to an access point, for instance using another iOS device running this app;\n- to estimate the Internet throughput for various locations on your local Wi-Fi network, select a target on the Internet, like flood.eowyn.eu.org.", comment: "Come back here after having started a TCP Flood Chargen action on a target (download speed testing).\nThe target must remain the same until the heat map is built.\n- to estimate the Wi-Fi internal throughput between local hosts, either select a target on the local wired network, or select a wirelessly connected target that is as close as possible to an access point, for instance using another iOS device running this app;\n- to estimate the Internet throughput for various locations on your local Wi-Fi network, select a target on the Internet, like flood.eowyn.eu.org."),
        "step 2/5:\n- at the bottom left of the map, you can see a white access point blinking;\n- go near an access point;\n- click on its location on the map to move the white access point to your location on the map;\n- on the vertical left scale, you can see the real time network speed;\n- when the speed is stable, associate this value to your access point by clicking on Add an access point or probe.",
        "step 3/5:\n- your first access point color has changed to black, this means it has been registered with the speed value at its location;\n- a new white access point is ready for a new value, at the bottom left of the map;\n- you may optionally want to take a measure far from an access point. In that case, click again on Add an access point or probe to change the image of the white access point to a probe one;\n- move to a new location to take a new measure;\n- click on the location on the map to move the white access point or probe to your location on the map;\n- when the speed on the vertical left scale is stable, associate this value to your location by clicking on Add an access point or probe.",
        "step 4/4:\n- you see a triangle since you have reached three measures;\n- the last one is located on the top bottom white access point;\n- you can optionally click again on Add an access point or probe to replace the white access point with a white probe;\n- click on the map to change the location of this third measure;\n- try different positions of the horizontal sliders to adjust the map;\n- click on Add an access point or probe to associate the speed measure to your current location and add another white access point at the bottom left of the map;\n- when finished, remove the latest white access point or probe by enabling the preview switch."
    ]
    
    @Published var input_map_image: UIImage?
    @Published var original_map_image: UIImage?
    @Published var original_map_image_rotation: Bool?
    @Published var idw_values = Array<IDWValue<Float>>()
    @Published var step = 0
    @Published var max_scale: Float = LOWEST_MAX_SCALE
}

enum NavigationTarget: Hashable {
    case step_choose_plan
    case step_heat_map
}

// Dans l'ordre :
// StepWelcomeView: propose 3 choix: advanced gui, step by step mode, doc
//   StepFloorPlan: propose de choisir un floor plan parmi 6
//

@MainActor
struct StepByStepSwiftUIView: View {
    @State private var showing_exit_popup = false
    @State private var showing_exit_button = false
    @State private var scale: CGFloat = 0.0
    @State private var navigation_path = NavigationPath()
    
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
                Text("WifiMapExplorer")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                Spacer()
            }.background(Color(COLORS.toolbar_background))

            // NavigationStack root screen: StepWelcomeView
            NavigationStack(path: $navigation_path) {
                StepWelcomeView(showing_exit_button: $showing_exit_button, showing_exit_popup: $showing_exit_popup, scale: $scale, navigation_path: $navigation_path)
            }
            .background(Color(COLORS.right_pannel_scroll_bg))
            .cornerRadius(15)

            if showing_exit_button {
                HStack {
                    Spacer()

                    Button("Advanced interface") {
                        showing_exit_popup = true
                    }
                    .opacity(scale)
                    .padding(0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            scale = 1
                        }
                    }

                    Spacer()

                    Button("Web site") {
                        UIApplication.shared.open(URL(string: "http://wifimapexplorer.com/new-manual.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))")!)
                    }
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

        }
        .padding(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
        .background(Color(COLORS.right_pannel_bg))
        .sheet(
            isPresented: $showing_exit_popup,
            content: {
                ModalPopPupShell(
                    action: {
                        step_by_step_view_controller?.dismiss(
                            animated: true)
                    },
                    NSLocalizedString(
                        "RETURNING TO THE APP HOME PAGE",
                        comment: "RETURNING TO THE APP HOME PAGE"),
                    NSLocalizedString("I understand", comment: "I Understand"),
                    {
                        Text("")
                        Text(
                            "You can come back later to the home window simply by clicking on the following icon:"
                        )
                        BlinkingContent {
                            Image(systemName: "house")
                                .scaleEffect(2)
                                .padding(10)
                        }

                        if UIDevice.current.userInterfaceIdiom != .phone
                            && ProcessInfo.processInfo.isMacCatalystApp == false
                        {
                            // We run on an iPad
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
                        }

                        Text("")
                    }
                )
                .background(Color(COLORS.right_pannel_scroll_bg))
            }
        )
    }
}

struct StepWelcomeView: View {
    @Binding var showing_exit_button: Bool
    @Binding var showing_exit_popup: Bool
    @Binding var scale: CGFloat
    @Binding var navigation_path: NavigationPath
    
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
                                Spacer()
                                Image("design-manual").resizable().aspectRatio(contentMode: .fit)
                                .padding(padding_size)
                            }
                            Spacer()
                        }
                    }.padding(padding_size)
                }

                Button(action: {
                    navigation_path.append(NavigationTarget.step_choose_plan)
                }) {
                    BlinkingContent {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Step-by-step easy mode")
                                Spacer()
                                Image("design-auto").resizable().aspectRatio(contentMode: .fit)
                                .padding(padding_size)
                            }
                            Spacer()
                        }
                    }.padding(padding_size)
                }.navigationDestination(for: NavigationTarget.self) { target in
                    if target == .step_choose_plan {
                        VStack {
                            Text("Choose a predefined floor plan or load an image")
                            OrientationView { is_portrait, size in
                                StepChoosePlan(navigation_path: $navigation_path, is_portrait: is_portrait, size: size)
                                    .onAppear {
                                        showing_exit_button = true
                                    }
                            }
                        }.background(Color(COLORS.right_pannel_scroll_bg))
                    } else {
                        StepHeatMap(navigation_path: $navigation_path)
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
                                Spacer()
                                Image("design-doc").resizable().aspectRatio(contentMode: .fit)
                                .padding(padding_size)
                            }
                            Spacer()
                        }
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
    @Binding var navigation_path: NavigationPath

    var body: some View {
        Text("HeatMap")
    }
}

struct StepChoosePlan: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showing_map_picker = false
    @State private var showing_alert = false

    @Binding var navigation_path: NavigationPath

    @ObservedObject var model = StepByStepViewModel.shared

    var is_portrait: Bool
    var size: CGSize

    var body: some View {
        VStack(alignment: .center) {
            if is_portrait {
                HStack(alignment: .center) {
                    Spacer()

                    NavigationLink {
                        StepHeatMap(navigation_path: $navigation_path)
                    } label: {
                        BlinkingContent {
                            Image("plan-rectangle").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(navigation_path: $navigation_path)
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
                        StepHeatMap(navigation_path: $navigation_path)
                    } label: {
                        BlinkingContent {
                            Image("plan-2rect").resizable().aspectRatio(contentMode: .fit)
                        }
                    }
                    
                    Spacer()

                    NavigationLink {
                        StepHeatMap(navigation_path: $navigation_path)
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
                        StepHeatMap(navigation_path: $navigation_path)
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
                        StepHeatMap(navigation_path: $navigation_path)
                    } label: {
                        BlinkingContent {
                            Image("plan-rectangle").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(navigation_path: $navigation_path)
                    } label: {
                        BlinkingContent {
                            Image("plan-T").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(navigation_path: $navigation_path)
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
                        StepHeatMap(navigation_path: $navigation_path)
                    } label: {
                        BlinkingContent {
                            Image("plan-thin").resizable().aspectRatio(contentMode: .fit)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StepHeatMap(navigation_path: $navigation_path)
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
                }
            }
    }
}

struct StepDocumentation: View {
    var body: some View {
        WebContent(
            url:
                "https://fenyo.net/wifimapexplorer/new-manual.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))"
        )
        .padding(20)
    }
}

@MainActor
class StepByStepPhotoController: NSObject {
    weak var step_by_step_view_controller: StepByStepViewController?

    public init(step_by_step_view_controller: StepByStepViewController) {
        self.step_by_step_view_controller = step_by_step_view_controller
    }

    @objc private func image(
        _ image: UIImage,
        didFinishPhotoLibrarySavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        //        print("Image successfully written to camera roll")
        exporting_map = false
        if error != nil {
            popUp(
                NSLocalizedString(
                    "Error saving map", comment: "Error saving map"),
                NSLocalizedString(
                    "Access to photos is forbidden. You need to change the access rights in the app configuration panel (click on the wheel button in the toolbar to access the configuration panel)",
                    comment:
                        "Access to photos is forbidden. You need to change the access rights in the app configuration panel (click on the wheel button in the toolbar to access the configuration panel)"
                ), "OK")
        } else {
            popUp(
                NSLocalizedString("Map saved", comment: "Map saved"),
                NSLocalizedString(
                    "You can find the heatmap in you photo roll",
                    comment: "You can find the heatmap in you photo roll"), "OK"
            )
        }
    }

    public func popUp(_ title: String, _ message: String, _ ok: String) {
        let alert = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: ok, style: .default) { _ in
            SKStoreReviewController.requestReview()
        }
        alert.addAction(action)
        self.step_by_step_view_controller?.present(alert, animated: true)
    }

    public func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(
            image, self,
            #selector(
                image(_:didFinishPhotoLibrarySavingWithError:contextInfo:)), nil
        )
    }
}

