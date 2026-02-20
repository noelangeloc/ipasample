
import UIKit
import WebKit

@MainActor
func sendPushToWebView(userInfo: [AnyHashable: Any]) {
    guard let webView = WebViewStore.webView else { return }
    if let data = try? JSONSerialization.data(withJSONObject: userInfo),
       let json = String(data: data, encoding: .utf8) {
        webView.evaluateJavaScript("window.onPushNotification && window.onPushNotification(\(json))")
    }
}
