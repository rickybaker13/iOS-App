import SwiftUI
import QuickLook

struct ResourcePreviewItem: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

struct ResourcePreviewController: UIViewControllerRepresentable {
    let item: ResourcePreviewItem
    
    func makeCoordinator() -> Coordinator {
        Coordinator(item: item)
    }
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let item: ResourcePreviewItem
        
        init(item: ResourcePreviewItem) {
            self.item = item
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            item.url as NSURL
        }
    }
}

