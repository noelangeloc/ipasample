import WebKit
import FirebaseMessaging
import UserNotifications
import UIKit

@MainActor
func returnPermissionResult(isGranted: Bool) {
    let result = isGranted ? "granted" : "denied"
    Sample.webView.evaluateJavaScript(
        "this.dispatchEvent(new CustomEvent('push-permission-request', { detail: '\(result)' }))"
    )
}

func handleFCMToken() {
    Messaging.messaging().token { token, _ in
        Task { @MainActor in
            if let token {
                Sample.webView.evaluateJavaScript(
                    "this.dispatchEvent(new CustomEvent('push-token', { detail: '\(token)' }))"
                )
            }
        }
    }
}

func sendPushToWebView(userInfo: [AnyHashable: Any]) {
    if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
       let json = String(data: jsonData, encoding: .utf8) {
        Task { @MainActor in
            Sample.webView.evaluateJavaScript(
                "this.dispatchEvent(new CustomEvent('push-notification', { detail: \(json) }))"
            )
        }
    }
}
