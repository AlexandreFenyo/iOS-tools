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

@MainActor
struct HeatMapSwiftUIView: View {
    let heatmap_view_controller: HeatMapViewController

    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var image: Image?

    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Heat Map Builder")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                    .onChange(of: inputImage) { _ in loadImage() }

                
                    .sheet(isPresented: $showingImagePicker) {
                        ImagePicker(image: $inputImage)
                    }

                Spacer()
            }.background(Color(COLORS.toolbar_background))
            
            VStack {
                HStack() {

                    HStack(alignment: .top) {
                        Button {
                            /* Si on voulait accéder aux photos sans passer par le picker
                            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                                print("XXXX status: \(status)")
                             // PHPhotoLibrary.shared().register(self)
                            }*/

                            showingImagePicker = true
                        } label: {
                            VStack {
                                Image(systemName: "map").resizable().frame(width: 40, height: 30)
                                Text("Select your map").font(.footnote).frame(maxWidth: 200)
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

                if let image {
                    image
                       .resizable()
                       .aspectRatio(contentMode: .fit)
                    
                }
                Spacer()
                Text("saltu")
                
            }
                .background(Color(COLORS.right_pannel_scroll_bg))
                .cornerRadius(15).padding(10)

            Button("Hide map") {
                heatmap_view_controller.dismiss(animated: true)
            }.padding()
            
        }.background(Color(COLORS.right_pannel_bg))
    }
}
