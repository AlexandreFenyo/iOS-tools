import SwiftUI

/* Usage:
 var body: some View {
     BlinkingContent {
         Text("clignotement")
     }
 }
*/

struct BlinkingContent<Content: View>: View {
    @State private var is_highlighted = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .overlay(
                Rectangle()
                    .stroke(
                        is_highlighted ? Color.red : Color.clear, lineWidth: 4
                    )
                    .animation(
                        Animation.linear(duration: 0.5).repeatForever(
                            autoreverses: true), value: is_highlighted)
            )
            .onAppear {
                is_highlighted = true
            }
    }
}
