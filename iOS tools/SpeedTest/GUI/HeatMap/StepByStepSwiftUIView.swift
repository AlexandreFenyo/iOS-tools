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

struct StepFloorPlan: View {
    var is_portrait: Bool
    var size: CGSize

    var body: some View {
        VStack(alignment: .center) {
            if is_portrait {
                HStack {
                    BlinkingContent {
                        Image("plan-rectangle").resizable().aspectRatio(contentMode: .fit)
                    }
                    BlinkingContent {
                        Image("plan-T").resizable().aspectRatio(contentMode: .fit)
                    }
                }

                HStack {
                    BlinkingContent {
                        Image("plan-2rect").resizable().aspectRatio(contentMode: .fit)
                    }
                    BlinkingContent {
                        Image("plan-thin").resizable().aspectRatio(contentMode: .fit)
                    }
                }
                
                HStack {
                    BlinkingContent {
                        Image("plan-bgonly").resizable().aspectRatio(contentMode: .fit)
                    }
                    BlinkingContent {
                        Image("plan-empty").resizable().aspectRatio(contentMode: .fit)
                    }
                }
            } else {
                HStack {
                    BlinkingContent {
                        Image("plan-rectangle").resizable().aspectRatio(contentMode: .fit)
                    }
                    BlinkingContent {
                        Image("plan-T").resizable().aspectRatio(contentMode: .fit)
                    }
                    BlinkingContent {
                        Image("plan-2rect").resizable().aspectRatio(contentMode: .fit)
                    }
                }
                
                HStack {
                    BlinkingContent {
                        Image("plan-thin").resizable().aspectRatio(contentMode: .fit)
                    }
                    BlinkingContent {
                        Image("plan-bgonly").resizable().aspectRatio(contentMode: .fit)
                    }
                    BlinkingContent {
                        Image("plan-empty").resizable().aspectRatio(contentMode: .fit)
                    }
                }
            }

            /*
            HStack {
                Image("plan-rectangle").resizable().aspectRatio(
                    contentMode: .fit)
                Image("plan-T").resizable().aspectRatio(contentMode: .fit)
            }
            HStack {
                Image("plan-2rect").resizable().aspectRatio(contentMode: .fit)
                Image("plan-2rectreverse").resizable().aspectRatio(
                    contentMode: .fit)
            }
            HStack {
                Image("plan-bgonly").resizable().aspectRatio(contentMode: .fit)
                Image("plan-empty").resizable().aspectRatio(contentMode: .fit)
            }
             */
            //            }

        }.padding(.top)
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

struct StepWelcomeView: View {
    @Binding var showing_exit_button: Bool
    @Binding var showing_exit_popup: Bool
    @Binding var scale: CGFloat

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
                                Image("design-manual").resizable().aspectRatio(
                                    contentMode: .fit
                                )
                                .padding(padding_size)
                            }
                            Spacer()
                        }
                    }.padding(padding_size)
                }

                NavigationLink {
                    Text("Choose your preferred floor plan")
                    OrientationView { is_portrait, size in
                        StepFloorPlan(is_portrait: is_portrait, size: size)
                            .onAppear {
                                showing_exit_button = true
                            }
                    }
                    NavigationLink("Work Folder") {
                        Text("nav link 1")
                        Text("nav link 2")
                    }

                } label: {
                    BlinkingContent {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Step-by-step easy mode")
                                Spacer()
                                Image("design-auto").resizable().aspectRatio(
                                    contentMode: .fit
                                )
                                .padding(padding_size)
                            }
                            Spacer()
                        }
                    }.padding(padding_size)
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
                                Image("design-doc").resizable().aspectRatio(
                                    contentMode: .fit
                                )
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

@MainActor
struct StepByStepSwiftUIView: View {
    @State private var showing_exit_popup = false
    @State private var showing_exit_button = false
    @State private var scale: CGFloat = 0.0

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

            NavigationStack {
                StepWelcomeView(
                    showing_exit_button: $showing_exit_button,
                    showing_exit_popup: $showing_exit_popup, scale: $scale)
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
                        UIApplication.shared.open(
                            URL(
                                string:
                                    "http://wifimapexplorer.com/new-manual.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))"
                            )!)
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
