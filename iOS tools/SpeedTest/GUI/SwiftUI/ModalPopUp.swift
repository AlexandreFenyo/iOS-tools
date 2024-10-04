import SwiftUI

/*
 struct ContentView: View {
    @State private var showing_popup = false
    var body: some View {
        LandscapePortraitView {
            Text("123")
            Text("456")
        }.onTapGesture {
            showing_popup = true
        }.sheet(isPresented: $showing_popup, content: {
            ModalPopUp("NOTE", "You can come back to this page", "I understand") {
                Text("salut")
            }
            .presentationDetents([.fraction(0.2)])
        })
    }
 }
*/

// Display a modal popup
struct ModalPopUp<Content: View>: View {
    let content: Content
    let title: String
    let text: String
    let dismiss: String

    @Environment(\.presentationMode) var presentationMode

    init(_ title: String, _ text: String, _ dismiss: String, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.title = title
        self.text = text
        self.dismiss = dismiss
    }

    var body: some View {
        Text(title)
        Spacer()
        Text(text)
        content
        Spacer()

        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Text(dismiss)
        }
    }

}
