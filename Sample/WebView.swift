import UIKit
import WebKit

@MainActor
func createWebView(
    container: UIView,
    WKSMH: WKScriptMessageHandler,
    WKND: WKNavigationDelegate,
    NSO: NSObject,
    VC: ViewController
) -> WKWebView {

    let config = WKWebViewConfiguration()
    let controller = WKUserContentController()
    controller.add(WKSMH, name: "print")
    config.userContentController = controller

    let webView = WKWebView(frame: container.bounds, configuration: config)
    setCustomCookie(webView: webView)
    webView.navigationDelegate = WKND
    return webView
}

@MainActor
func setCustomCookie(webView: WKWebView) {
    if let host = rootUrl.host {
        let cookie = HTTPCookie(properties: [
            .domain: host,
            .path: "/",
            .name: platformCookie.name,
            .value: platformCookie.value,
            .secure: "FALSE"
        ])!
        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
    }
}
