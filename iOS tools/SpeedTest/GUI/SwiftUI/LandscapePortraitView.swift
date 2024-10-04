import SwiftUI

/* usage:
struct ContentView: View {
    var body: some View {
        LandscapePortraitView {
            Text("123")
            Text("456")
        }
    }
 }
*/

// Display a View in a HStack when in portrait mode and in a VStack otherwise
struct LandscapePortraitView<Content: View>: View {
    @State private var is_portrait: Bool = true
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            if #available(iOS 17.0, *) {
                makeBody()
                    .onAppear {
                        is_portrait =
                        geometry.size.width < geometry.size.height
                    }
                    .onChange(of: geometry.size) { _, new_value in
                        is_portrait =
                        new_value.width < new_value.height
                    }
            } else {
                makeBody()
                    .onAppear {
                        is_portrait =
                        geometry.size.width < geometry.size.height
                    }
                    .onChange(of: geometry.size) { new_value in
                        is_portrait =
                        new_value.width < new_value.height
                    }
            }
        }
    }

    @ViewBuilder
    private func makeBody() -> some View {
        if is_portrait {
            VStack {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }
}
