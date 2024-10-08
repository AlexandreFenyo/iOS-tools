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
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        is_highlighted ? Color.red : Color.clear, lineWidth: 2
                    )
                    .animation(
                        Animation.linear(duration: 0.5).repeatForever(
                            autoreverses: true), value: is_highlighted)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    is_highlighted = true
                }
            }
    }
}
