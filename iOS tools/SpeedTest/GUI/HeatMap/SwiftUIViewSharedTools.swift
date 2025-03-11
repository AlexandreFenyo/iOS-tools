//
//  SwiftUIViewSharedTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 11/03/2025.
//  Copyright © 2025 Alexandre Fenyo. All rights reserved.
//

import iOSToolsMacros
import UIKit

func computeMergedImage(image_rotation: Bool, image: UIImage, idw_image: IDWImage, power_scale: Float, power_scale_radius: Float, factor_x: Float, power_blur_radius: CGFloat) async -> UIImage {
    let (cg_image, _) = await idw_image.computeCGImageAsync(power_scale: power_scale, power_scale_radius: power_scale_radius * factor_x, distance_cache: nil)
    
    let ci_image_map = CIImage(cgImage: cg_image!)
    let ci_image_map_ext = ci_image_map.extent
    let ci_image_clamped = ci_image_map.clampedToExtent()
    let ci_context_blur = CIContext()
    let blur = CIFilter(name: "CIGaussianBlur")!
    blur.setValue(ci_image_clamped, forKey: kCIInputImageKey)
    blur.setValue(power_blur_radius * CGFloat(factor_x), forKey: kCIInputRadiusKey)
    let blurred_image = blur.outputImage
    let new_blur_cg_image = ci_context_blur.createCGImage(blurred_image!, from: ci_image_map_ext)
    let blur_image = UIImage(cgImage: new_blur_cg_image!)
    let ci_image_original = CIImage(cgImage: image.cgImage!)
    let ci_image_original_ext = ci_image_original.extent
    let ci_context_grayscale = CIContext()
    let grayscale = CIFilter(name: "CIPhotoEffectNoir")!
    grayscale.setValue(ci_image_original, forKey: kCIInputImageKey)
    var gray_image = grayscale.outputImage
    
    if image_rotation {
        gray_image = gray_image?.oriented(CGImagePropertyOrientation.upMirrored)
    }
    
    let new_grayscale_cg_image = ci_context_grayscale.createCGImage(gray_image!, from: ci_image_original_ext)
    let grayscale_image = UIImage(cgImage: new_grayscale_cg_image!)
    
    let size = CGSize(width: cg_image!.width, height: cg_image!.height)
    UIGraphicsBeginImageContext(size)
    let area_size = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    blur_image.draw(in: area_size,blendMode: .normal, alpha: 1.0)
    grayscale_image.draw(in: area_size, blendMode: .normal, alpha: 0.2)
    let merged_image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    return merged_image
}
