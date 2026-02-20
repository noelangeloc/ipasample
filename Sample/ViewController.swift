import UIKit
import WebKit

@MainActor
class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    @IBOutlet weak var webviewView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        Sample.webView = createWebView(
            container: webviewView,
            WKSMH: self,
            WKND: self,
            NSO: self,
            VC: self
        )
        webviewView.addSubview(Sample.webView)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if message.name == "print" {
            printView(webView: Sample.webView)
        }
    }
}
