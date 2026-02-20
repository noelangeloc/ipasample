import UIKit
import WebKit
import FirebaseMessaging
import UserNotifications

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
