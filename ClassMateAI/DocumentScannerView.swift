import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    typealias Completion = (Result<Data, Error>) -> Void
    
    let onComplete: Completion
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: Completion
        
        init(onComplete: @escaping Completion) {
            self.onComplete = onComplete
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let pdfData = NSMutableData()
            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
                onComplete(.failure(NSError(domain: "scanner", code: -1)))
                return
            }
            var mediaBox = CGRect.zero
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                onComplete(.failure(NSError(domain: "scanner", code: -2)))
                return
            }
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                var pageRect = CGRect(origin: .zero, size: image.size)
                context.beginPage(mediaBox: &pageRect)
                guard let cgImage = image.cgImage else { continue }
                context.draw(cgImage, in: pageRect)
                context.endPage()
            }
            context.closePDF()
            controller.dismiss(animated: true) {
                self.onComplete(.success(pdfData as Data))
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true, completion: nil)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) {
                self.onComplete(.failure(error))
            }
        }
    }
}

