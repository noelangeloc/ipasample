
import UIKit
import WebKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let webView = WKWebView(frame: view.bounds)
        WebViewStore.webView = webView
        view.addSubview(webView)

        if let url = URL(string: "https://example.com") {
            webView.load(URLRequest(url: url))
        }
    }
}
