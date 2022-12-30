
import PhotosUI
import SwiftUI

// https://www.hackingwithswift.com/books/ios-swiftui/importing-an-image-into-swiftui-using-phpickerviewcontroller

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var original_map_image: UIImage?
    @Binding var idw_values: Array<IDWValue<Float>>

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
        
//        static let MAX_SIZE = 1024 // remettre 1024, on met 10240 pour trouver ce qui accroit la mémoire indéfiniement
// impact sur les performances
        static let MAX_SIZE = 600

        static func rotateIfNeeded(_ img: UIImage) -> UIImage {
            if img.cgImage!.width < img.cgImage!.height {
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: img.cgImage!.height, height: img.cgImage!.width))
                let image = renderer.image { _ in
                    let context = UIGraphicsGetCurrentContext()
                    context?.rotate(by: Double.pi / 2)
                    context?.draw(img.cgImage!, in: CGRect(origin: CGPoint(x: 0, y: -img.cgImage!.height), size: CGSize(width: img.cgImage!.width, height: img.cgImage!.height)))
                }
                return image.withHorizontallyFlippedOrientation()
            }
            return img
        }
        
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
                            let resized_image = Coordinator.resizeIfNeeded(Coordinator.rotateIfNeeded(image))
                            self.parent.original_map_image = Coordinator.rotateIfNeeded(image)
                            self.parent.image = resized_image
                            self.parent.idw_values = Array<IDWValue>()
                        }
                    }
                }
            } else {
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        Task {
                            let resized_image = Coordinator.resizeIfNeeded(Coordinator.rotateIfNeeded(image as! UIImage))
                            self.parent.original_map_image = Coordinator.rotateIfNeeded(image as! UIImage)
                            self.parent.image = resized_image
                            self.parent.idw_values = Array<IDWValue>()

                            return

                            // pour tester avec trois mesures déjà réalisées
                            /*
                            self.parent.idw_values.append(IDWValue<Float>(x: 100, y: 100, v: 500.0, type: .ap))
                            self.parent.idw_values.append(IDWValue<Float>(x: 150, y: 150, v: 400.0, type: .ap))
                            self.parent.idw_values.append(IDWValue<Float>(x: 100, y: 150, v: 300.0, type: .ap))
                             */

                            /*
                            self.parent.idw_values.insert(IDWValue<Float>(x: 250, y: 150, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 250, y: 150, v: 10000000.0, type: .probe))

                            return
                            
                            self.parent.idw_values.insert(IDWValue<Float>(x: 550, y: 250, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 550, y: 250, v: 10000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 650, y: 250, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 650, y: 250, v: 10000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 750, y: 250, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 750, y: 250, v: 10000000.0, type: .probe))

                            self.parent.idw_values.insert(IDWValue<Float>(x: 250+50, y: 350, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 250+50, y: 350, v: 5000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 350+50, y: 350, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 350+50, y: 350, v: 5000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 450+50, y: 350, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 450+50, y: 350, v: 5000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 550+50, y: 350, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 550+50, y: 350, v: 5000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 650+50, y: 350, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 650+50, y: 350, v: 5000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 750+50, y: 350, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 750+50, y: 350, v: 5000000.0, type: .probe))
                            
                            self.parent.idw_values.insert(IDWValue<Float>(x: 250, y: 450, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 250, y: 450, v: 1000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 350, y: 450, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 350, y: 450, v: 1000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 450, y: 450, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 450, y: 450, v: 1000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 550, y: 450, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 550, y: 450, v: 1000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 650, y: 450, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 650, y: 450, v: 1000000.0, type: .probe))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 750, y: 450, v: 600.0, type: .ap))
                            self.parent.idw_values.insert(IDWValue<Float>(x: 750, y: 450, v: 1000000.0, type: .probe))
*/
                        }
                    }
                }
            }
        }
    }
}
