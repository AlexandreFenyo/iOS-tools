
import PhotosUI
import SwiftUI

// https://www.hackingwithswift.com/books/ios-swiftui/importing-an-image-into-swiftui-using-phpickerviewcontroller

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var idw_values: Set<IDWValue<Float>>

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        static let MAX_SIZE = 1024 // remettre 1024, on met 10240 pour trouver ce qui accroit la mémoire indéfiniement
        static func resizeIfNeeded(_ img: UIImage) -> UIImage {
            if img.cgImage!.width > MAX_SIZE || img.cgImage!.height > MAX_SIZE {
                let size: CGSize
                if img.cgImage!.width > img.cgImage!.height {
                    size = CGSize(width: MAX_SIZE, height: img.cgImage!.height * MAX_SIZE / img.cgImage!.width)
                } else {
                    size = CGSize(width: img.cgImage!.width * MAX_SIZE / img.cgImage!.height, height: MAX_SIZE)
                }
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                    img.draw(in: CGRect(origin: .zero, size: size))
                }
                return image
            }
            return img
        }
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }

            if provider.hasItemConformingToTypeIdentifier(UTType.webP.identifier) {
                // support des images HEIF (ne fonctionne pas sur simulateur)
                provider.loadDataRepresentation(forTypeIdentifier: UTType.webP.identifier) {data, err in
                    if let data = data, let image = UIImage.init(data: data) {
                        Task {
                            let resized_image = Coordinator.resizeIfNeeded(image)
                            self.parent.image = resized_image
                            self.parent.idw_values = Set<IDWValue>()
                        }
                    }
                }
            } else {
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        Task {
                            let resized_image = Coordinator.resizeIfNeeded(image as! UIImage)
                            self.parent.image = resized_image
                            self.parent.idw_values = Set<IDWValue>()

                            // pour tester avec une mesure déjà réalisée
                            self.parent.idw_values.insert(IDWValue<Float>(x: 100, y: 100, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 100, y: 100, v: 10000000.0, type: .probe))
                        }
                    }
                }
            }
        }
    }
}
