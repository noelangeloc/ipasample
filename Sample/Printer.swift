import UIKit
import WebKit

@MainActor
func printView(webView: WKWebView) {

    let printController = UIPrintInteractionController.shared

    let printInfo = UIPrintInfo(dictionary: nil)
    printInfo.outputType = .general
    printInfo.jobName = webView.url?.absoluteString ?? "Print"
    printInfo.duplex = .none
    printInfo.orientation = .portrait

    let renderer = UIPrintPageRenderer()
    renderer.addPrintFormatter(
        webView.viewPrintFormatter(),
        startingAtPageAt: 0
    )

    printController.printInfo = printInfo
    printController.printPageRenderer = renderer
    printController.showsNumberOfCopies = true
    printController.present(animated: true)
}
