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
    let action: () -> Void
    let shell_content: Content
    let title: String
    let dismiss: String
    // Note: this is the size of the components added by ModalPopUp
    let other_components_height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 300 : 500

    init(
        action: @escaping () -> Void,
        _ title: String, _ dismiss: String,
        @ViewBuilder _ shell_content: () -> Content
    ) {
        self.action = action
        self.shell_content = shell_content()
        self.title = title
        self.dismiss = dismiss
    }

    var body: some View {
        ModalPopUp(
            action: action,
            title,
            dismiss
        ) {
            shell_content
        }
        .onPreferenceChange(SizePreferenceKey.self) { size in
            view_height = size
            frac =
                (view_height.height + other_components_height) / UIScreen.main.bounds.height
        }
        .presentationDetents([.fraction(frac)])
    }
}

// Display a modal popup
struct ModalPopUp<Content: View>: View {
    let content: Content
    let title: String
    let dismiss: String
    let action: () -> Void

    @Environment(\.presentationMode) var presentationMode

    init(
        action: @escaping () -> Void,
        _ title: String, _ dismiss: String,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
        self.title = title
        self.dismiss = dismiss
    }

    var body: some View {
        // Note: the estimated size of the components added by ModalPopUp, like Text(title) and Text(dismiss), MUST be set in ModalPopPupShell.other_components_height

        Text(title).bold().padding(10)

        Rectangle()
            .fill(Color.gray)
            .frame(height: 2)
            .padding(.horizontal)

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
            action()
        }) {
            VStack {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 2)
                    .padding(.horizontal)
                
                Text(dismiss).padding(10)
            }
        }
    }
}