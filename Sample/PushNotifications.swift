
import UIKit
import WebKit

@MainActor
func sendPushToWebView(userInfo: [AnyHashable: Any]) {
    guard let webView = WebViewStore.webView else { return }
    if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
       let json = String(data: jsonData, encoding: .utf8) {
        webView.evaluateJavaScript("window.onPushNotification && window.onPushNotification(\(json))")
    }
}
