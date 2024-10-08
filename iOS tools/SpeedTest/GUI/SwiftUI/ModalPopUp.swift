import Foundation
import SwiftUI

/* Usage:
 struct ContentView: View {
     @State private var showing_popup = false

     var body: some View {
         LandscapePortraitView {
             Text("123")
             Text("456")
         }.onTapGesture {
             showing_popup = true
         }.sheet(
             isPresented: $showing_popup,
             content: { ModalPopPupShell(
                 "Titre", "J'ai compris", {
                     Text("""
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
 */

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}


struct ModalPopPupShell<Content: View>: View {
    @State private var frac: CGFloat = 0.8
    @State private var view_height: CGSize = .zero
    let shell_content: Content
    let title: String
    let dismiss: String
    // Note: this is the size of the components added by ModalPopUp
    let other_components_height: CGFloat = 200

    init(
        _ title: String, _ dismiss: String,
        @ViewBuilder _ shell_content: () -> Content
    ) {
        self.shell_content = shell_content()
        self.title = title
        self.dismiss = dismiss
    }

    var body: some View {
        ModalPopUp(
            title,
            dismiss
        ) {
            shell_content
        }
        .onPreferenceChange(SizePreferenceKey.self) { size in
            view_height = size
            frac =
                (view_height.height + other_components_height)
                / UIScreen.main.bounds.height
            print("frac = \(frac)")
        }
        .presentationDetents([.fraction(frac)])

    }
}

// Display a modal popup
struct ModalPopUp<Content: View>: View {
    let content: Content
    let title: String
    let dismiss: String

    @Environment(\.presentationMode) var presentationMode

    init(
        _ title: String, _ dismiss: String,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.title = title
        self.dismiss = dismiss
    }

    var body: some View {
        // Note: the estimated size of the components added by ModalPopUp, like Text(title) and Text(dismiss), MUST be set in ModalPopPupShell.other_components_height

        Text(title)
        if UIDevice.current.userInterfaceIdiom != .phone { Spacer() }
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: SizePreferenceKey.self, value: geometry.size)
                }
            )
        if UIDevice.current.userInterfaceIdiom != .phone { Spacer() }
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text(dismiss)
        }
    }
}
