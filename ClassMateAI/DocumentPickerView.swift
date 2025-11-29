import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    typealias Callback = (URL) -> Void
    
    let supportedTypes: [UTType]
    let onPick: Callback
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        controller.delegate = context.coordinator
        controller.allowsMultipleSelection = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: Callback
        
        init(onPick: @escaping Callback) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

