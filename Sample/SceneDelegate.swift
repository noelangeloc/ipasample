import UIKit

@MainActor
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    static var universalLinkToLaunch: URL?
    static var shortcutLinkToLaunch: URL?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let userActivity = connectionOptions.userActivities.first {
            scene(scene, continue: userActivity)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }

        Sample.webView.evaluateJavaScript("location.href = '\(url)'")
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        if let url = URL(string: shortcutItem.type) {
            Sample.webView.evaluateJavaScript("location.href = '\(url)'")
        }
        completionHandler(true)
    }
}
