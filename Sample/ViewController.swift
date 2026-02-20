import UIKit
import WebKit

@MainActor
class ViewController: UIViewController,
                      WKNavigationDelegate,
                      WKUIDelegate,
                      UIDocumentInteractionControllerDelegate,
                      WKScriptMessageHandler {

    var documentController: UIDocumentInteractionController?

    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var connectionProblemView: UIImageView!
    @IBOutlet weak var webviewView: UIView!

    var toolbarView: UIToolbar!
    var htmlIsLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        initWebView()
        initToolbarView()
        loadRootUrl()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Sample.webView.frame = calcWebviewFrame(
            webviewView: webviewView,
            toolbarView: toolbarView?.isHidden == true ? nil : toolbarView
        )
    }

    func initWebView() {
        Sample.webView = createWebView(
            container: webviewView,
            WKSMH: self,
            WKND: self,
            NSO: self,
            VC: self
        )

        webviewView.addSubview(Sample.webView)
        Sample.webView.uiDelegate = self
    }

    func initToolbarView() {
        toolbarView = UIToolbar()
        toolbarView.isHidden = true
        webviewView.addSubview(toolbarView)
    }

    @objc func loadRootUrl() {
        Sample.webView.load(URLRequest(url: rootUrl))
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "print":
            printView(webView: Sample.webView)
        case "push-token":
            handleFCMToken()
        default:
            break
        }
    }
}
