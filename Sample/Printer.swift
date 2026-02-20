import UIKit
import WebKit

@MainActor
func printView(webView: WKWebView) {
    let controller = UIPrintInteractionController.shared
    let info = UIPrintInfo(dictionary: nil)
    info.outputType = .general
    controller.printInfo = info
    controller.printFormatter = webView.viewPrintFormatter()
    controller.present(animated: true)
}
