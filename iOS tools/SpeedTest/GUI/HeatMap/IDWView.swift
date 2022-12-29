//
//  ContentView.swift
//  testimages2
//
//  Created by Alexandre Fenyo on 30/10/2022.

// https://fr.wikipedia.org/wiki/Pondération_inverse_à_la_distance

import SwiftUI

// private var debugcnt = 0

private let NTHREADS = 10

public enum ProbeType {
    case probe
    case ap
}

public struct IDWValue<V: Hashable>: Hashable {
    public var type: ProbeType = .probe
    public let x: UInt16
    public let y: UInt16
    // v: débit dans la plupart des cas
    public let v: V
    
    init(x: UInt16, y: UInt16, v: V, type: ProbeType = .probe) {
        self.x = x
        self.y = y
        self.v = v
        self.type = type
    }
}

private protocol FloatOrUInt16 {
    func toFloat() -> Float
}

extension UInt16: FloatOrUInt16 {
    func toFloat() -> Float { Float(self) }
}

extension Float: FloatOrUInt16 {
    func toFloat() -> Float { self }
}

private func distanceFloat(_ x0: any FloatOrUInt16, _ y0: any FloatOrUInt16, _ x1: any FloatOrUInt16, _ y1: any FloatOrUInt16) -> Float {
    pow(pow(x0.toFloat() - x1.toFloat(), 2) + pow(y0.toFloat() - y1.toFloat(), 2), 0.5)
}

public struct IDWImage {
    public typealias PixelBytes = UnsafeMutablePointer<UInt8>
    private let bits_per_component = 8
    private let ncomponents = 3
    private let width: UInt16
    private let height: UInt16
    private var values = Set<IDWValue<UInt16>>()
    public let npixels: Int
    public let nbytes_per_line: Int
    public let nbytes_per_pixel: Int
    
    public func getValues() -> Set<IDWValue<UInt16>> {
        return values
    }

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
    
    private static func getRGB(_ val: UInt16) -> (r: UInt8, g: UInt8, b: UInt8) {
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
        let pos_vertical = Int(height) - Int(idwval.y) - 1
        let pos_horizontal = Int(idwval.x)
        if pos_vertical < 0 || pos_vertical >= height || pos_horizontal < 0 || pos_horizontal >= width { return }
        let p = pixels + (pos_vertical * nbytes_per_line + pos_horizontal * nbytes_per_pixel)
        let rgb = Self.getRGB(idwval.v)
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

    public static func getScaleImage(height: UInt16) -> CGImage? {
        let pixels = PixelBytes.allocate(capacity: 3 * Int(height))
        pixels.initialize(repeating: 0, count: 3 * Int(height))
        for i in 0..<height {
            let p = pixels + Int(i) * 3
            let rgb = getRGB(UInt16(Float(height - i - 1) / Float(height) * Float(UInt16.max)))
            p.pointee = rgb.r
            (p + 1).pointee = rgb.g
            (p + 2).pointee = rgb.b
        }
        let data = CFDataCreate(nil, pixels, 3 * Int(height))
        pixels.deallocate()
        guard let provider = CGDataProvider(data: data!) else {
            return nil
        }

        let img = CGImage(width: 1, height: Int(height), bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: 3, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: .byteOrderDefault, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)

        return img
    }
    
    public func computeCGImageAsync(power_scale: Float, power_scale_radius: Float, debug_x: UInt16? = nil, debug_y: UInt16? = nil, distance_cache: DistanceCache?) async -> (CGImage?, DistanceCache?) {
        let now = Date()
        
        var _poly = Polygon(vertices: values.map { CGPoint(x: Double($0.x), y: Double($0.y)) })
        if _poly.vertices.count >= 3 { _poly.computeConvexHull() }
        let poly = _poly
        
        let pixels = PixelBytes.allocate(capacity: npixels * 3)
        pixels.initialize(repeating: 0, count: npixels * nbytes_per_pixel)
        
        for idw in values {
            setBoldPixel(pixels, idw)
        }
        
        let storage = UnsafeMutablePointer<UInt16>.allocate(capacity: distance_cache != nil ? 1 : Int(width) * Int(height))
        storage.initialize(repeating: 0, count: distance_cache != nil ? 1 : Int(width) * Int(height))
        
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
                                var d = distanceFloat(x, y, idw.x, idw.y)
                                d = pow(d, power_scale)
                                val += Float(idw.v) / d
                                denom += 1 / d
                            }

                            let dist_to_poly: Float
                            if let distance_cache {
                                dist_to_poly = Float(distance_cache.getDistance(x: x, y: y))
                            } else {
                                dist_to_poly = Float(poly.distanceToPolygon(CGPoint(x: Double(x), y: Double(y))))
                                let p: UnsafeMutablePointer<UInt16> = storage + (Int(x) + Int(width) * Int(y))
                                p.pointee = UInt16(dist_to_poly)
                            }
                            
                            if power_scale_radius > 0 {
                                if dist_to_poly != 0 {
                                    // on est en dehors du polygone
                                    if dist_to_poly < power_scale_radius {
                                        // on est dans la zone des 200 à l'extérieur du polygone
                                        var d = power_scale_radius - dist_to_poly
                                        d = pow(d, power_scale)
                                        denom += 1 / d
                                    } else {
                                        // on est au delà de la zone des 200 à l'extérieur du polygone
                                        val = 0
                                        denom = 1
                                    }
                                }
                            }
                            
                            if true {
                                if denom.isNormal && !denom.isZero && val.isNormal {
                                    val = val / denom
                                    if val > Float(UInt16.max) || val < Float(UInt16.min) {
                                    } else {
                                        setPixel(pixels, IDWValue(x: x, y: y, v: UInt16(val)))
                                    }
                                } else {
                                    setPixel(pixels, IDWValue(x: x, y: y, v: 0))
                                }
                            }
                        }
                    }
                    return
                } // addTask
            }
        })
        
        let data = CFDataCreate(nil, pixels, npixels * 3)
        pixels.deallocate()
        
        guard let provider = CGDataProvider(data: data!) else {
            storage.deallocate()
            return (nil, nil)
        }
        
        let cg_image = CGImage(width: Int(width), height: Int(height), bitsPerComponent: bits_per_component, bitsPerPixel: ncomponents * bits_per_component, bytesPerRow: (ncomponents * bits_per_component / 8) * Int(width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: .byteOrderDefault, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        if distance_cache == nil {
            var distance = [UInt16]()
            for i in 0..<Int(width) * Int(height) {
                distance.append((storage + Int(i)).pointee)
            }
            storage.deallocate()
            
            let distance_cache = DistanceCache(width: width, height: height, vertices: Set(values.map { CGPoint(x: Double($0.x), y: Double($0.y)) }), distance: distance)

            print("durée computeCGImageAsync: \(Date().timeIntervalSince(now)) s")
            return (cg_image, distance_cache)
        }
        
        //        fatalError()
        print("durée computeCGImageAsync: \(Date().timeIntervalSince(now)) s")
        return (cg_image, nil)
    }
}
