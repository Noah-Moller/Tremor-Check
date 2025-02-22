import SwiftUI
import PDFKit
import UIKit

class PDFGenerator {
    static func generateMultiPagePDF(from views: [AnyView], completion: @escaping (Data?) -> Void) {
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageSize = CGSize(width: pageWidth, height: pageHeight)

        let format = UIGraphicsPDFRendererFormat()
        let metaData = [
            kCGPDFContextCreator: "Tremor Check App",
            kCGPDFContextAuthor: "Tremor Check App",
            kCGPDFContextTitle: "Tremor Assessment Report"
        ]
        format.documentInfo = metaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        
        let data = renderer.pdfData { context in
            for (index, view) in views.enumerated() {
                context.beginPage()

                let hostingController = UIHostingController(rootView: view)
                hostingController.view.bounds = CGRect(origin: .zero, size: pageSize)
                hostingController.view.backgroundColor = .white

                let window = UIWindow(frame: CGRect(origin: .zero, size: pageSize))
                window.rootViewController = hostingController
                window.makeKeyAndVisible()

                hostingController.view.setNeedsLayout()
                hostingController.view.layoutIfNeeded()

                hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)

                window.isHidden = true
            }
        }
        
        completion(data)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            DispatchQueue.main.async {
                isPresented = false
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
