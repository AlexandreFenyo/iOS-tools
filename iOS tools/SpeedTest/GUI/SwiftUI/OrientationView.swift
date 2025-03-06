//
//  OrientationView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 20/10/2024.
//  Copyright © 2024 Alexandre Fenyo. All rights reserved.
//

import Foundation
import SwiftUI

/* usage:
struct ContentView: View {
    var body: some View {
        OrientationView { is_portrait in
          InsideView(is_portrait: is_portrait)
 ...
 
struct InsideView: View {
    var is_portrait: Bool
...
*/

struct OrientationView<Content: View>: View {
    @State private var is_portrait: Bool = true
    @State private var size: CGSize = CGSize()
    let content: (Bool, CGSize) -> Content

    init(@ViewBuilder content: @escaping (Bool, CGSize) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            if #available(iOS 17.0, *) {
                makeBody()
                    .onAppear {
                        is_portrait = geometry.size.width < geometry.size.height
                        size = geometry.size
                    }
                    .onChange(of: geometry.size) { _, new_value in
                        is_portrait = new_value.width < new_value.height
                        size = geometry.size
                    }
            } else {
                makeBody()
                    .onAppear {
                        is_portrait = geometry.size.width < geometry.size.height
                        size = geometry.size
                    }
                    .onChange(of: geometry.size) { new_value in
                        is_portrait = new_value.width < new_value.height
                        size = geometry.size
                    }
                
            }
        }
    }

    @ViewBuilder
    private func makeBody() -> some View {
        content(is_portrait, size)
    }
}
