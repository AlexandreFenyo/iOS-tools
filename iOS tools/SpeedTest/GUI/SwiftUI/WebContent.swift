import SwiftUI
import WebKit

/* Usage:
 let url: URL = URL("https://google.com")!
 var body: some View {
        WebContent(url: url).background(.red)
 }
*/

struct WebContent: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
