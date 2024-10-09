import SwiftUI
import WebKit

/* Usage:
 var body: some View {
    WebContent(url: "https://fenyo.net/wifimapexplorer/new-manual.html")
 }
*/

struct WebContent: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let url = URL(string: url)!
        uiView.load(URLRequest(url: url))
        uiView.allowsBackForwardNavigationGestures = true
    }
}
