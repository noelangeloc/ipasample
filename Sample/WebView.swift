import UIKit
import WebKit
import AuthenticationServices
import SafariServices

@MainActor
func createWebView(
    container: UIView,
    WKSMH: WKScriptMessageHandler,
    WKND: WKNavigationDelegate,
    NSO: NSObject,
    VC: ViewController
) -> WKWebView {

    let config = WKWebViewConfiguration()
    let userContentController = WKUserContentController()

    userContentController.add(WKSMH, name: "print")
    userContentController.add(WKSMH, name: "push-subscribe")
    userContentController.add(WKSMH, name: "push-permission-request")
    userContentController.add(WKSMH, name: "push-permission-state")
    userContentController.add(WKSMH, name: "push-token")

    config.userContentController = userContentController
    config.limitsNavigationsToAppBoundDomains = true
    config.allowsInlineMediaPlayback = true
    config.preferences.javaScriptCanOpenWindowsAutomatically = true
    config.preferences.setValue(true, forKey: "standalone")

    let webView = WKWebView(
        frame: calcWebviewFrame(webviewView: container, toolbarView: nil),
        configuration: config
    )

    setCustomCookie(webView: webView)

    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    webView.isHidden = true
    webView.navigationDelegate = WKND
    webView.scrollView.bounces = false
    webView.scrollView.contentInsetAdjustmentBehavior = .never
    webView.allowsBackForwardNavigationGestures = true

    if #available(iOS 16.4, macOS 13.3, *) {
        webView.isInspectable = true
    }

    let deviceModel = UIDevice.current.model
    let osVersion = UIDevice.current.systemVersion

    webView.configuration.applicationNameForUserAgent = "Safari/604.1"
    webView.customUserAgent =
        "Mozilla/5.0 (\(deviceModel); CPU \(deviceModel) OS \(osVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(osVersion) Mobile/15E148 Safari/604.1 PWAShell"

    webView.addObserver(
        NSO,
        forKeyPath: #keyPath(WKWebView.estimatedProgress),
        options: .new,
        context: nil
    )

    #if DEBUG
    if #available(iOS 16.4, *) {
        webView.isInspectable = true
    }
    #endif

    return webView
}

func setAppStoreAsReferrer(contentController: WKUserContentController) {
    let scriptSource = "document.referrer = `app-info://platform/ios-store`;"
    let script = WKUserScript(
        source: scriptSource,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )
    contentController.addUserScript(script)
}

func setCustomCookie(webView: WKWebView) {
    let platformCookie = HTTPCookie(properties: [
        .domain: rootUrl.host!,
        .path: "/",
        .name: platformCookie.name,
        .value: platformCookie.value,
        .secure: "FALSE",
        .expires: NSDate(timeIntervalSinceNow: 31556926)
    ])!

    webView.configuration.websiteDataStore.httpCookieStore.setCookie(platformCookie)
}

@MainActor
func calcWebviewFrame(webviewView: UIView, toolbarView: UIToolbar?) -> CGRect {
    if let toolbarView {
        return CGRect(
            x: 0,
            y: toolbarView.frame.height,
            width: webviewView.frame.width,
            height: webviewView.frame.height - toolbarView.frame.height
        )
    }

    let winScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
    var statusBarHeight = winScene.statusBarManager?.statusBarFrame.height ?? 0

    switch displayMode {
    case "fullscreen":
        #if targetEnvironment(macCatalyst)
        winScene.titlebar?.titleVisibility = .hidden
        winScene.titlebar?.toolbar = nil
        #endif
        return CGRect(x: 0, y: 0, width: webviewView.frame.width, height: webviewView.frame.height)
    default:
        #if targetEnvironment(macCatalyst)
        statusBarHeight = 29
        #endif
        let height = webviewView.frame.height - statusBarHeight
        return CGRect(x: 0, y: statusBarHeight, width: webviewView.frame.width, height: height)
    }
}

extension ViewController: WKUIDelegate, WKDownloadDelegate {

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.request.url?.scheme == "about" {
            decisionHandler(.allow)
            return
        }

        if navigationAction.shouldPerformDownload || navigationAction.request.url?.scheme == "blob" {
            decisionHandler(.download)
            return
        }

        guard let requestUrl = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if let host = requestUrl.host {
            if authOrigins.contains(where: { host.contains($0) }) {
                decisionHandler(.allow)
                toolbarView.isHidden = false
                webView.frame = calcWebviewFrame(webviewView: webviewView, toolbarView: toolbarView)
                return
            }

            if allowedOrigins.contains(where: { host.contains($0) }) {
                decisionHandler(.allow)
                toolbarView.isHidden = true
                webView.frame = calcWebviewFrame(webviewView: webviewView, toolbarView: nil)
                return
            }
        }

        decisionHandler(.cancel)

        if ["http", "https"].contains(requestUrl.scheme?.lowercased() ?? "") {
            present(SFSafariViewController(url: requestUrl), animated: true)
        } else if UIApplication.shared.canOpenURL(requestUrl) {
            UIApplication.shared.open(requestUrl)
        }
    }

    func downloadAndOpenFile(url: URL) {
        let request = URLRequest(url: url)
        URLSession.shared.downloadTask(with: request) { tempUrl, _, _ in
            guard let tempUrl else { return }
            do {
                try FileManager.default.copyItem(at: tempUrl, to: url)
                Task { @MainActor in
                    self.openFile(url: url)
                }
            } catch {
                print(error)
            }
        }.resume()
    }

    @MainActor
    func openFile(url: URL) {
        documentController = UIDocumentInteractionController(url: url)
        documentController?.delegate = self
        documentController?.presentPreview(animated: true)
    }
}
