//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import PhotosUI
import SpriteKit
import StoreKit
import SwiftUI

// CONTINUER ICI : NavigationStack

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

struct StepWelcomeView2: View {
    var body: some View {
        HStack(alignment: .top) {
            Text("Salut")
            Spacer()
            NavigationLink("Work Folder") {
                Text("nav link 1")
                Text("nav link 2")
            }
        }.padding(.top)
    }
}

struct StepWelcomeView: View {
    @Binding var showing_exit_button: Bool
    
    let padding_size: CGFloat = 10
    var body: some View {
        VStack(alignment: .center) {

            LandscapePortraitView {
                
                NavigationLink {
                    StepWelcomeView2().onAppear {
                        print("APPEAR")
                        showing_exit_button = true
                    }
                } label: {
                    BlinkingContent {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Go to manual interface")
                                Spacer()
                                Image("design-manual").resizable().aspectRatio(contentMode: .fit)
                                    .padding(padding_size)
                            }
                            Spacer()
                        }
                    }.padding(padding_size)
                }
                
                NavigationLink {
                    StepWelcomeView2().onAppear {
                        print("APPEAR")
                        showing_exit_button = true
                    }
                } label: {
                    BlinkingContent {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Step-by-step")
                                Spacer()
                                Image("design-auto").resizable().aspectRatio(contentMode: .fit)
                                    .padding(padding_size)
                            }
                            Spacer()
                        }
                    }.padding(padding_size)
                }

                NavigationLink {
                    StepWelcomeView2().onAppear {
                        print("APPEAR")
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
                }
            }
        }//.padding(.top)  //.background(.red)
    }
}

@MainActor
struct StepByStepSwiftUIView: View {
    @State private var showing_exit_popup = false
    @State private var showing_exit_button = false

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
                Text("Heat Map Builder")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                Spacer()
            }.background(Color(COLORS.toolbar_background))

            NavigationStack {
                StepWelcomeView(showing_exit_button: $showing_exit_button)
            }
            .background(Color(COLORS.right_pannel_scroll_bg))
            .cornerRadius(15).padding(10)

            if showing_exit_button {
                Button("Quit step-by-step mode") {
                    showing_exit_button = true
                    step_by_step_view_controller?.dismiss(animated: true)
                }.padding()
                
            }
            
        }.background(Color(COLORS.right_pannel_bg))
            .sheet(
                isPresented: $showing_exit_popup,
                content: {
                    ModalPopPupShell(
                        action: {
                            step_by_step_view_controller?.dismiss(
                                animated: true)
                        },

                        "Titre", "J'ai compris",
                        {
                            Text(
                                """
                                   You can come back \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   fzeozeifjefz oijzfe oiezfj \
                                   to this page
                                """)
                        })
                }
            )

    }
}
