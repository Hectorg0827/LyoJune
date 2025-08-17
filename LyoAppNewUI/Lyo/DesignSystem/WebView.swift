import SwiftUI
import WebKit

/// A SwiftUI view that wraps a `WKWebView` from UIKit, allowing web content to be displayed.
struct WebView: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

#if DEBUG
struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with a sample YouTube embed URL
        if let url = URL(string: "https://www.youtube.com/embed/dQw4w9WgXcQ") {
            WebView(url: url)
        } else {
            Text("Invalid URL")
        }
    }
}
#endif
