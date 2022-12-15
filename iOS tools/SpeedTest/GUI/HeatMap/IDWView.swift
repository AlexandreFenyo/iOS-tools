//
//  ContentView.swift
//  testimages2
//
//  Created by Alexandre Fenyo on 30/10/2022.

// https://fr.wikipedia.org/wiki/Pondération_inverse_à_la_distance

import SwiftUI

private let NTHREADS = 10

public enum ProbeType {
    case probe
    case ap
}

public struct IDWValue<V: Hashable>: Hashable {
    public var type: ProbeType = .probe
    public let x: UInt16
    public let y: UInt16
    // si type == probe, alors v est une valeur de débit, sinon c'est le rayon en pixels d'un cercle centré en (x, y) et valant 0 sur toute sa circonférence et en dehors du cercle
    public let v: V
    
    init(x: UInt16, y: UInt16, v: V, type: ProbeType = .probe) {
        self.x = x
        self.y = y
        self.v = v
        self.type = type
    }
}

public struct IDWImage {
    //    private var my_memory_tracker = MyMemoryTracker("IDWImage")
    
    public typealias PixelBytes = UnsafeMutablePointer<UInt8>
    private let bits_per_component = 8
    private let ncomponents = 3
    private let width: UInt16
    private let height: UInt16
    private var values = Set<IDWValue<UInt16>>()
    public let npixels: Int
    public let nbytes_per_line: Int
    public let nbytes_per_pixel: Int
    
    // power / 2 correspond à l'exposant dans le calcul de la distance, donc power == 1 implique sqrt, plus on augmente et plus on valorise les points les plus proches
    public let power: Float = 1.0
//    public let power: Float = 1.5

    // yellow_size indique l'importance du jaune dans les couleurs utilisées
    public static let yellow_size: Float = 1.5
    
    public static let rgb_from_value: [(r: UInt8, g: UInt8, b: UInt8)] = {
        var tab = [(r: UInt8, g: UInt8, b: UInt8)]()
        let fmax = Float(UInt16.max)
        for i in 0...UInt16.max {
            var fi = Float(i)
            var ii = pow(abs((fi - fmax / 2.0)) / (fmax / 2.0), yellow_size)
            if fi < fmax / 2.0 { ii = -ii }
            ii = 0.5 + ii / 2.0
            ii = ii * fmax
            let hue: Double = Double(Float(ii) / Float(UInt16.max) * 0.33)
            let c = Color(hue: hue, saturation: 1, brightness: 1, opacity: 1)
            tab.insert((r: UInt8((c.cgColor?.components)![0] * CGFloat(UInt8.max)), g: UInt8((c.cgColor?.components)![1] * CGFloat(UInt8.max)), b: UInt8((c.cgColor?.components)![2] * CGFloat(UInt8.max))), at: tab.count)
        }
        return tab
    }()
    
    private func getRGB(_ val: UInt16) -> (r: UInt8, g: UInt8, b: UInt8) {
        return Self.rgb_from_value[Int(val)]
    }
    
    public init(width: UInt16, height: UInt16) {
        self.width = width
        self.height = height
        npixels = Int(width) * Int(height)
        nbytes_per_pixel = ncomponents * bits_per_component / 8
        nbytes_per_line = Int(width) * nbytes_per_pixel
    }
    
    public mutating func addValue(_ val: IDWValue<UInt16>) -> Bool {
        if values.contains(val) { return false }
        values.insert(val)
        return true
    }
    
    public mutating func removeValue(_ val: IDWValue<UInt16>) -> Bool {
        return values.remove(val) == nil ? false : true
    }
    
    private func setPixel(_ pixels: PixelBytes, _ idwval: IDWValue<UInt16>) {
        let p = (pixels + ((Int(height) - Int(idwval.y) - 1) * nbytes_per_line)) + Int(idwval.x) * nbytes_per_pixel
        let rgb = getRGB(idwval.v)
        p.pointee = rgb.r
        (p + 1).pointee = rgb.g
        (p + 2).pointee = rgb.b
    }
    
    private func setBoldPixel(_ pixels: PixelBytes, _ idwval: IDWValue<UInt16>) {
        setPixel(pixels, idwval)
        if idwval.x == 0 || idwval.x == UInt16.max || idwval.y == 0 || idwval.y == UInt16.max { return }
        setPixel(pixels, IDWValue(x: idwval.x, y: idwval.y - 1, v: idwval.v))
        setPixel(pixels, IDWValue(x: idwval.x, y: idwval.y + 1, v: idwval.v))
        setPixel(pixels, IDWValue(x: idwval.x - 1, y: idwval.y, v: idwval.v))
        setPixel(pixels, IDWValue(x: idwval.x + 1, y: idwval.y, v: idwval.v))
    }
    
    private func distance_power_p(_ x0: UInt16, _ y0: UInt16, _ x1: UInt16, _ y1: UInt16, _ p: Float) -> Float {
        let dist = pow(pow(Float(x0) - Float(x1), 2) + pow(Float(y0) - Float(y1), 2), p / 2)
        return dist
    }
    
    
    public func computeCGImageAsync(_ only_markers: Bool = false) async -> CGImage? {
        let now = Date()
        
        let pixels = PixelBytes.allocate(capacity: npixels * 3)
        pixels.initialize(repeating: 0, count: npixels * nbytes_per_pixel)
        
        for idw in values {
            setBoldPixel(pixels, idw)
        }
        
        if (!only_markers) {
            await withTaskGroup(of: Void.self, body: { group in
                let remainder = height % UInt16(NTHREADS)
                let nthreads = remainder != 0 ? NTHREADS + 1 : NTHREADS
                let lines_per_thread = height / UInt16(NTHREADS)
                for thr in 0..<nthreads {
                    group.addTask {
                        let start_y = UInt16(thr) * lines_per_thread
                        var end_y = start_y + lines_per_thread
                        if end_y > height { end_y = height }
                        for x in 0..<width {
                            for y in start_y..<end_y {
                                var val: Float = 0
                                var denom: Float = 0
                                for idw in values {
                                    if idw.type == .probe {
                                        let d = distance_power_p(x, y, idw.x, idw.y, power)
                                        val += Float(idw.v) / d
                                        denom += 1 / d
                                    } else {
//                                        if (Int32(x) - Int32(idw.x)) * (Int32(x) - Int32(idw.x)) + (Int32(y) - Int32(idw.y)) * (Int32(y) - Int32(idw.y)) > Int32(idw.v) * Int32(idw.v) {
                                        if distance_power_p(x, y, idw.x, idw.y, power) > Float(idw.v) {
                                            val = 0
                                            denom = 1
                                            break
                                        } else {
                                            let d = Float(idw.v) - distance_power_p(x, y, idw.x, idw.y, power)
                                            val += Float(idw.v) / d
                                            denom += 1 / d
                                        }
                                    }
                                }
                                if denom.isNormal && !denom.isZero && val.isNormal {
                                    val = val / denom
                                    setPixel(pixels, IDWValue(x: x, y: y, v: UInt16(val)))
                                } else {
                                    setPixel(pixels, IDWValue(x: x, y: y, v: 0))
                                }
                            }
                        }
                        return
                    } // addTask
                }
            })
        }
        
        let data = CFDataCreate(nil, pixels, npixels * 3)
        pixels.deallocate()
        
        guard let provider = CGDataProvider(data: data!) else { return nil }
        
        let cg_image = CGImage(width: Int(width), height: Int(height), bitsPerComponent: bits_per_component, bitsPerPixel: ncomponents * bits_per_component, bytesPerRow: (ncomponents * bits_per_component / 8) * Int(width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: .byteOrderDefault, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        print("durée computeCGImageAsync: \(Date().timeIntervalSince(now)) s")
        
        return cg_image
    }
}
