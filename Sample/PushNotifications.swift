import WebKit
import FirebaseMessaging
import UserNotifications
import UIKit

class SubscribeMessage {
    var topic = ""
    var eventValue = ""
    var unsubscribe = false

    struct Keys {
        static let TOPIC = "topic"
        static let UNSUBSCRIBE = "unsubscribe"
        static let EVENTVALUE = "eventValue"
    }

    convenience init(dict: [String: Any]) {
        self.init()
        topic = dict[Keys.TOPIC] as? String ?? ""
        unsubscribe = dict[Keys.UNSUBSCRIBE] as? Bool ?? false
        eventValue = dict[Keys.EVENTVALUE] as? String ?? ""
    }
}

// MARK: - Topic Subscription

func handleSubscribeTouch(message: WKScriptMessage) {
    let subscribeMessages = parseSubscribeMessage(message: message)

    guard let msg = subscribeMessages.first else { return }

    if msg.unsubscribe {
        Messaging.messaging().unsubscribe(fromTopic: msg.topic) { _ in }
    } else {
        Messaging.messaging().subscribe(toTopic: msg.topic) { _ in }
    }
}

func parseSubscribeMessage(message: WKScriptMessage) -> [SubscribeMessage] {
    var results = [SubscribeMessage]()

    guard let objStr = message.body as? String,
          let data = objStr.data(using: .utf8) else { return results }

    if let json = try? JSONSerialization.jsonObject(with: data) {
        if let dict = json as? [String: Any] {
            results.append(SubscribeMessage(dict: dict))
        } else if let arr = json as? [[String: Any]] {
            results = arr.map { SubscribeMessage(dict: $0) }
        }
    }

    return results
}

// MARK: - WebView Messaging (MainActor)

@MainActor
func returnPermissionResult(isGranted: Bool) {
    let result = isGranted ? "granted" : "denied"
    Sample.webView.evaluateJavaScript(
        "this.dispatchEvent(new CustomEvent('push-permission-request', { detail: '\(result)' }))"
    )
}

@MainActor
func returnPermissionState(state: String) {
    Sample.webView.evaluateJavaScript(
        "this.dispatchEvent(new CustomEvent('push-permission-state', { detail: '\(state)' }))"
    )
}

func handlePushPermission() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        switch settings.authorizationStatus {
        case .notDetermined:
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: options) { success, _ in
                Task { @MainActor in
                    returnPermissionResult(isGranted: success)
                    if success {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }

        case .denied:
            Task { @MainActor in returnPermissionResult(isGranted: false) }

        case .authorized, .ephemeral, .provisional:
            Task { @MainActor in returnPermissionResult(isGranted: true) }

        @unknown default:
            break
        }
    }
}

func handlePushState() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        Task { @MainActor in
            switch settings.authorizationStatus {
            case .notDetermined: returnPermissionState(state: "notDetermined")
            case .denied: returnPermissionState(state: "denied")
            case .authorized: returnPermissionState(state: "authorized")
            case .ephemeral: returnPermissionState(state: "ephemeral")
            case .provisional: returnPermissionState(state: "provisional")
            @unknown default: returnPermissionState(state: "unknown")
            }
        }
    }
}

@MainActor
func checkViewAndEvaluate(event: String, detail: String) {
    guard !Sample.webView.isHidden,
          !Sample.webView.isLoading else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            checkViewAndEvaluate(event: event, detail: detail)
        }
        return
    }

    Sample.webView.evaluateJavaScript(
        "this.dispatchEvent(new CustomEvent('\(event)', { detail: \(detail) }))"
    )
}

func handleFCMToken() {
    Messaging.messaging().token { token, _ in
        Task { @MainActor in
            if let token {
                checkViewAndEvaluate(event: "push-token", detail: "'\(token)'")
            } else {
                checkViewAndEvaluate(event: "push-token", detail: "'ERROR'")
            }
        }
    }
}

func sendPushToWebView(userInfo: [AnyHashable: Any]) {
    if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
       let json = String(data: jsonData, encoding: .utf8) {
        Task { @MainActor in
            checkViewAndEvaluate(event: "push-notification", detail: json)
        }
    }
}

func sendPushClickToWebView(userInfo: [AnyHashable: Any]) {
    if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
       let json = String(data: jsonData, encoding: .utf8) {
        Task { @MainActor in
            checkViewAndEvaluate(event: "push-notification-click", detail: json)
        }
    }
}
