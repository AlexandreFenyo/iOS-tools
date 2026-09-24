//
//  frise-screenshots.swift — frises App Store (appareils en perspective sur un fond continu)
//
//  Alternative à compose-screenshots.swift, qui pose un bandeau sur chaque capture : ici
//  les captures brutes sont insérées dans un appareil dessiné (iPhone 17 Pro Max, iPad Pro
//  13" en paysage, MacBook Pro), incliné et en perspective, sur un fond menthe traversé
//  d'un graphe réseau continu ; la bande est ensuite découpée en panneaux aux formats
//  App Store Connect. Dans la page App Store, les panneaux défilent côte à côte et forment
//  une frise : certains appareils chevauchent deux panneaux.
//
//  Usage :  swift scripts/frise-screenshots.swift [répertoire-screenshots] [locales]
//           locales : liste séparée par des virgules (ex. en-US,fr-FR) ; vide = toutes
//
//  Lit scripts/screenshot-captions.tsv (légendes, ordre des écrans) et, pour chaque locale
//  et chaque appareil dont les captures brutes existent, écrit
//    <dir>/<locale>/<appareil>-frise/<index>_<scénario>.png   (+ frise-complete.png)
//  Appareils : iphone69 (1320x2868), ipad13-landscape (2752x2064), mac (2880x1800 si la
//  capture brute vient d'un écran Retina, 1440x900 sinon — jamais d'agrandissement flou).
//  Les mises en scène sont réglées pour 6 écrans ; au-delà, disposition régulière.
//
import AppKit
import CoreImage

let script_url = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let root = script_url.deletingLastPathComponent().deletingLastPathComponent()
let base = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : root.appendingPathComponent("ASO/screenshots").path
let locale_filter: Set<String> = CommandLine.arguments.count > 2 && !CommandLine.arguments[2].isEmpty
    ? Set(CommandLine.arguments[2].split(separator: ",").map(String.init)) : []
let cs = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: a)
}
func rr(_ r: CGRect, _ rad: CGFloat) -> CGPath { CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil) }
func bitmap(_ w: CGFloat, _ h: CGFloat) -> CGContext {
    CGContext(data: nil, width: Int(w), height: Int(h), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}
let metal = CGGradient(colorsSpace: cs, colors: [color(0xB9BEC4), color(0xE4E6E9), color(0x9CA1A8), color(0xD6D9DD), color(0xA7ACB2)] as CFArray,
                       locations: [0, 0.18, 0.5, 0.82, 1])!

// Écran arrondi + reflet sur le verre
func drawScreen(_ ctx: CGContext, _ screen: CGImage, _ scr: CGRect, _ radius: CGFloat, glass: CGRect, glassRadius: CGFloat) {
    ctx.saveGState(); ctx.addPath(rr(scr, radius)); ctx.clip(); ctx.draw(screen, in: scr); ctx.restoreGState()
    ctx.saveGState(); ctx.addPath(rr(glass, glassRadius)); ctx.clip()
    let shine = CGGradient(colorsSpace: cs, colors: [color(0xFFFFFF, 0.10), color(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(shine, start: CGPoint(x: glass.minX, y: glass.maxY), end: CGPoint(x: glass.midX, y: glass.midY), options: [])
    ctx.restoreGState()
}

// --- iPhone 17 Pro Max ---
func iphone(_ screen: CGImage) -> CGImage {
    let sw = CGFloat(screen.width), sh = CGFloat(screen.height)
    let rim: CGFloat = 16, bezel: CGFloat = 52, margin: CGFloat = 14, R: CGFloat = 250
    let bw = sw + 2 * (rim + bezel), bh = sh + 2 * (rim + bezel)
    let ctx = bitmap(bw + 2 * margin, bh + 2 * margin)
    let body = CGRect(x: margin, y: margin, width: bw, height: bh)
    ctx.setFillColor(color(0x8E949B))
    for (y, len) in [(bh * 0.70, 150.0), (bh * 0.60, 230.0), (bh * 0.50, 230.0)] {
        ctx.addPath(rr(CGRect(x: 0, y: margin + y, width: margin + 6, height: len), 6)); ctx.fillPath()
    }
    for (y, len) in [(bh * 0.60, 330.0), (bh * 0.32, 200.0)] {
        ctx.addPath(rr(CGRect(x: body.maxX - 6, y: margin + y, width: margin + 6, height: len), 6)); ctx.fillPath()
    }
    ctx.saveGState(); ctx.addPath(rr(body, R)); ctx.clip()
    ctx.drawLinearGradient(metal, start: CGPoint(x: body.minX, y: 0), end: CGPoint(x: body.maxX, y: 0), options: []); ctx.restoreGState()
    ctx.addPath(rr(body.insetBy(dx: 2, dy: 2), R - 2)); ctx.setStrokeColor(color(0xFFFFFF, 0.55)); ctx.setLineWidth(3); ctx.strokePath()
    let glass = body.insetBy(dx: rim, dy: rim)
    ctx.addPath(rr(glass, R - rim)); ctx.setFillColor(color(0x050506)); ctx.fillPath()
    let scr = glass.insetBy(dx: bezel, dy: bezel)
    drawScreen(ctx, screen, scr, R - rim - bezel, glass: glass, glassRadius: R - rim)
    let island = CGRect(x: scr.midX - 187, y: scr.maxY - 33 - 111, width: 374, height: 111)
    ctx.addPath(rr(island, 55.5)); ctx.setFillColor(color(0x000000)); ctx.fillPath()
    return ctx.makeImage()!
}

// --- iPad Pro 13" en paysage ---
func ipad(_ screen: CGImage) -> CGImage {
    let sw = CGFloat(screen.width), sh = CGFloat(screen.height)
    let rim: CGFloat = 14, bezel: CGFloat = 78, margin: CGFloat = 12, R: CGFloat = 150
    let bw = sw + 2 * (rim + bezel), bh = sh + 2 * (rim + bezel)
    let ctx = bitmap(bw + 2 * margin, bh + 2 * margin)
    let body = CGRect(x: margin, y: margin, width: bw, height: bh)
    ctx.setFillColor(color(0x8E949B))   // bouton du haut et volume (bord supérieur en paysage)
    ctx.addPath(rr(CGRect(x: body.minX + bw * 0.08, y: body.maxY - 6, width: 190, height: margin + 6), 6)); ctx.fillPath()
    ctx.addPath(rr(CGRect(x: body.maxX - 6, y: body.maxY - bh * 0.22, width: margin + 6, height: 180), 6)); ctx.fillPath()
    ctx.saveGState(); ctx.addPath(rr(body, R)); ctx.clip()
    ctx.drawLinearGradient(metal, start: CGPoint(x: 0, y: body.minY), end: CGPoint(x: 0, y: body.maxY), options: []); ctx.restoreGState()
    ctx.addPath(rr(body.insetBy(dx: 2, dy: 2), R - 2)); ctx.setStrokeColor(color(0xFFFFFF, 0.55)); ctx.setLineWidth(3); ctx.strokePath()
    let glass = body.insetBy(dx: rim, dy: rim)
    ctx.addPath(rr(glass, R - rim)); ctx.setFillColor(color(0x050506)); ctx.fillPath()
    let scr = glass.insetBy(dx: bezel, dy: bezel)
    drawScreen(ctx, screen, scr, 55, glass: glass, glassRadius: R - rim)
    // Caméra frontale au centre du bord long supérieur
    ctx.setFillColor(color(0x1B1F26)); ctx.fillEllipse(in: CGRect(x: glass.midX - 13, y: glass.maxY - bezel / 2 - 13, width: 26, height: 26))
    return ctx.makeImage()!
}

// --- MacBook Pro ---
func macbook(_ screen: CGImage) -> CGImage {
    let sw = CGFloat(screen.width), sh = CGFloat(screen.height)
    let side = sw * 0.022, top = sw * 0.03, bottom = sw * 0.022, rim = sw * 0.006
    let lidW = sw + 2 * (side + rim), lidH = sh + top + bottom + 2 * rim
    let baseW = lidW * 1.14, baseH = sw * 0.032
    let ctx = bitmap(baseW, lidH + baseH)
    // Base en aluminium, plus large que l'écran, avec l'encoche d'ouverture
    let base = CGRect(x: 0, y: 0, width: baseW, height: baseH)
    ctx.saveGState(); ctx.addPath(rr(base, baseH * 0.45)); ctx.clip()
    let baseGrad = CGGradient(colorsSpace: cs, colors: [color(0x8A9098), color(0xD9DCE0), color(0xC3C7CC)] as CFArray, locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(baseGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: baseH), options: [])
    ctx.restoreGState()
    ctx.addPath(rr(CGRect(x: baseW / 2 - sw * 0.09, y: baseH * 0.55, width: sw * 0.18, height: baseH * 0.45), baseH * 0.2))
    ctx.setFillColor(color(0x9EA3AA)); ctx.fillPath()
    // Écran (couvercle)
    let lid = CGRect(x: (baseW - lidW) / 2, y: baseH, width: lidW, height: lidH)
    let R = sw * 0.035
    ctx.addPath(rr(lid, R)); ctx.setFillColor(color(0xA9AEB5)); ctx.fillPath()
    let glass = lid.insetBy(dx: rim, dy: rim)
    ctx.addPath(rr(glass, R - rim)); ctx.setFillColor(color(0x050506)); ctx.fillPath()
    let scr = CGRect(x: glass.minX + side, y: glass.minY + bottom, width: sw, height: sh)
    drawScreen(ctx, screen, scr, sw * 0.012, glass: glass, glassRadius: R - rim)
    // Encoche de la caméra
    let nw = sw * 0.11, nh = top * 0.95
    ctx.addPath(rr(CGRect(x: scr.midX - nw / 2, y: scr.maxY - nh * 0.55, width: nw, height: nh), nh * 0.35)); ctx.setFillColor(color(0x050506)); ctx.fillPath()
    return ctx.makeImage()!
}


// Perspective : k > 0 éloigne le bord droit, k < 0 le bord gauche
let ci = CIContext(options: [.workingColorSpace: cs])
func perspective(_ img: CGImage, _ k: CGFloat) -> CGImage {
    guard k != 0 else { return img }
    let w = CGFloat(img.width), h = CGFloat(img.height)
    let s = abs(k) * h / 2, dx = abs(k) * w * 0.35
    let f = CIFilter(name: "CIPerspectiveTransform")!
    f.setValue(CIImage(cgImage: img), forKey: kCIInputImageKey)
    if k > 0 {
        f.setValue(CIVector(x: 0, y: h), forKey: "inputTopLeft"); f.setValue(CIVector(x: 0, y: 0), forKey: "inputBottomLeft")
        f.setValue(CIVector(x: w - dx, y: h - s), forKey: "inputTopRight"); f.setValue(CIVector(x: w - dx, y: s), forKey: "inputBottomRight")
    } else {
        f.setValue(CIVector(x: dx, y: h - s), forKey: "inputTopLeft"); f.setValue(CIVector(x: dx, y: s), forKey: "inputBottomLeft")
        f.setValue(CIVector(x: w, y: h), forKey: "inputTopRight"); f.setValue(CIVector(x: w, y: 0), forKey: "inputBottomRight")
    }
    let o = f.outputImage!
    return ci.createCGImage(o, from: o.extent, format: .RGBA8, colorSpace: cs)!
}


// Position d'un appareil : centre en panneaux (x) et en fraction de hauteur (y), taille en
// fraction de la hauteur du panneau, rotation en degrés, perspective k
struct Spot { let x, y, size, rot, k: CGFloat }

struct Layout {
    let panel: CGSize
    let draw: (CGImage) -> CGImage
    let band: CGFloat          // hauteur du bandeau de légende, en fraction de la hauteur
    let spots: [Spot]          // pour 6 écrans
    let order: [Int]           // ordre de dessin (de l'arrière vers l'avant)
}

func layout(_ device: String, rawWidth: Int) -> Layout {
    switch device {
    case "iphone69":
        let s: CGFloat = 2250 / 2868, c: CGFloat = 1180 / 2868
        return Layout(panel: CGSize(width: 1320, height: 2868), draw: iphone, band: 470 / 2868, spots: [
            Spot(x: 0.52, y: c, size: s, rot: -4, k: 0.10), Spot(x: 1.55, y: c - 0.014, size: s, rot: 5, k: -0.12),
            Spot(x: 2.78, y: c - 0.010, size: s, rot: -6, k: 0.14), Spot(x: 3.62, y: c + 0.007, size: s * 0.97, rot: 7, k: -0.10),
            Spot(x: 4.52, y: c, size: s, rot: -3, k: 0.08), Spot(x: 5.46, y: c - 0.007, size: s, rot: 4, k: -0.10),
        ], order: [0, 1, 3, 2, 4, 5])
    case "ipad13-landscape":
        // Par paires qui se chevauchent de part et d'autre d'une frontière de panneaux
        return Layout(panel: CGSize(width: 2752, height: 2064), draw: ipad, band: 0.19, spots: [
            Spot(x: 0.70, y: 0.39, size: 0.70, rot: -6, k: 0.13), Spot(x: 1.30, y: 0.37, size: 0.70, rot: 5, k: -0.13),
            Spot(x: 2.70, y: 0.38, size: 0.70, rot: -7, k: 0.14), Spot(x: 3.30, y: 0.37, size: 0.70, rot: 6, k: -0.13),
            Spot(x: 4.70, y: 0.39, size: 0.70, rot: -5, k: 0.12), Spot(x: 5.30, y: 0.37, size: 0.70, rot: 6, k: -0.13),
        ], order: [0, 1, 2, 3, 4, 5])
    default:
        let panel = rawWidth >= 2000 ? CGSize(width: 2880, height: 1800) : CGSize(width: 1440, height: 900)
        return Layout(panel: panel, draw: macbook, band: 0.19, spots: [
            Spot(x: 0.50, y: 0.40, size: 0.72, rot: 0, k: 0.05), Spot(x: 1.50, y: 0.40, size: 0.72, rot: 0, k: -0.05),
            Spot(x: 2.72, y: 0.40, size: 0.72, rot: 0, k: 0.07), Spot(x: 3.60, y: 0.40, size: 0.70, rot: 0, k: -0.06),
            Spot(x: 4.50, y: 0.40, size: 0.72, rot: 0, k: 0.05), Spot(x: 5.50, y: 0.40, size: 0.72, rot: 0, k: -0.05),
        ], order: [0, 1, 3, 2, 4, 5])
    }
}

func frise(device: String, shots: [CGImage], captions: [String], names: [String], out: String) throws {
    let N = shots.count
    let L = layout(device, rawWidth: shots[0].width)
    let PW = L.panel.width, PH = L.panel.height, W = PW * CGFloat(N)
    let U = min(PW, PH) / 1320
    let spots = N == L.spots.count ? L.spots
        : (0..<N).map { Spot(x: CGFloat($0) + 0.5, y: L.spots[0].y, size: L.spots[0].size, rot: 0, k: 0) }
    let order = N == L.spots.count ? L.order : Array(0..<N)

    let pano = CGContext(data: nil, width: Int(W), height: Int(PH), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                         bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // Fond menthe + graphe réseau continu (graine fixe : fond identique à chaque génération)
    let bgGrad = CGGradient(colorsSpace: cs, colors: [color(0xEAF6F1), color(0xD3ECE3)] as CFArray, locations: [0, 1])!
    pano.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: PH), end: CGPoint(x: 0, y: 0), options: [])
    var seed: UInt64 = 0x5EED
    func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(seed >> 33) / CGFloat(1 << 31) }
    var nodes: [CGPoint] = []
    for _ in 0..<Int(150 * (W * PH) / (7920 * 2868)) + 40 { nodes.append(CGPoint(x: rnd() * W, y: rnd() * PH)) }
    pano.setStrokeColor(color(0x5E9C8C, 0.28)); pano.setLineWidth(3 * U)
    for (i, a) in nodes.enumerated() {
        let near = nodes.enumerated().filter { $0.offset != i }
            .sorted { hypot($0.element.x - a.x, $0.element.y - a.y) < hypot($1.element.x - a.x, $1.element.y - a.y) }.prefix(2)
        for b in near { pano.move(to: a); pano.addLine(to: b.element) }
    }
    pano.strokePath()
    for (i, p) in nodes.enumerated() {
        let r: CGFloat = (i % 7 == 0 ? 26 : 13) * U
        pano.setFillColor(color(0x5E9C8C, i % 7 == 0 ? 0.30 : 0.38))
        pano.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
        if i % 7 == 0 {
            pano.setStrokeColor(color(0x5E9C8C, 0.35)); pano.setLineWidth(4 * U)
            pano.strokeEllipse(in: CGRect(x: p.x - r - 22 * U, y: p.y - r - 22 * U, width: 2 * r + 44 * U, height: 2 * r + 44 * U))
        }
    }

    // Appareils
    for i in order {
        let s = spots[i]
        let img = perspective(L.draw(shots[i]), s.k)
        let h = s.size * PH, w = h * CGFloat(img.width) / CGFloat(img.height)
        pano.saveGState()
        pano.translateBy(x: s.x * PW, y: s.y * PH); pano.rotate(by: s.rot * .pi / 180)
        pano.setShadow(offset: CGSize(width: 30 * U, height: -45 * U), blur: 90 * U, color: color(0x0B2B24, 0.40))
        pano.draw(img, in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        pano.restoreGState()
    }

    // Légendes : vrai texte (indexé par Apple), la plus grande taille qui tient en largeur
    for (i, text) in captions.enumerated() {
        let para = NSMutableParagraphStyle(); para.alignment = .center; para.lineHeightMultiple = 1.05
        var size: CGFloat = min(104 * U, L.band * PH * 0.36)
        let maxW = device == "iphone69" ? PW - 140 : PW * 0.8
        while size > 20 && text.split(separator: "\n").contains(where: {
            NSAttributedString(string: String($0), attributes: [.font: NSFont.systemFont(ofSize: size, weight: .heavy)]).size().width > maxW
        }) { size -= 1 }
        let s = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: .heavy),
            .foregroundColor: NSColor(srgbRed: 0.043, green: 0.106, blue: 0.169, alpha: 1), .paragraphStyle: para])
        let th = s.boundingRect(with: CGSize(width: PW - 60 * U, height: PH), options: [.usesLineFragmentOrigin]).height
        let rect = CGRect(x: CGFloat(i) * PW + 30 * U, y: PH - L.band * PH / 2 - th / 2, width: PW - 60 * U, height: th)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: pano, flipped: false)
        s.draw(with: rect, options: [.usesLineFragmentOrigin])
        NSGraphicsContext.restoreGraphicsState()
    }

    // PNG opaques (exigence App Store Connect) : panneaux + bande complète pour contrôle
    let full = pano.makeImage()!
    func save(_ img: CGImage, _ path: String) throws {
        try NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    }
    try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
    try save(full, "\(out)/frise-complete.png")
    for (i, n) in names.enumerated() {
        try save(full.cropping(to: CGRect(x: CGFloat(i) * PW, y: 0, width: PW, height: PH))!, "\(out)/\(n).png")
    }
}

// Lecture du TSV : locale -> (langue simulateur, [(index, scénario, légende)])
let tsv = try String(contentsOf: root.appendingPathComponent("scripts/screenshot-captions.tsv"), encoding: .utf8)
var locales: [(String, String, [(Int, String, String)])] = []
for line in tsv.split(separator: "\n").dropFirst() {
    let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    guard f.count >= 5, locale_filter.isEmpty || locale_filter.contains(f[0]) else { continue }
    let row = (Int(f[2]) ?? 0, f[3], f[4].replacingOccurrences(of: "\\n", with: "\n"))
    if let i = locales.firstIndex(where: { $0.0 == f[0] }) { locales[i].2.append(row) } else { locales.append((f[0], f[1], [row])) }
}

var count = 0
for (locale, lang, rows0) in locales {
    let rows = rows0.sorted { $0.0 < $1.0 }
    for device in ["iphone69", "ipad13-landscape", "mac"] {
        let dir = "\(base)/raw/\(lang)/\(device)"
        guard FileManager.default.fileExists(atPath: dir) else { continue }
        let shots = rows.compactMap { NSImage(contentsOfFile: "\(dir)/\($0.1).png")?.cgImage(forProposedRect: nil, context: nil, hints: nil) }
        guard shots.count == rows.count else { print("manquant : captures de \(dir)"); continue }
        try frise(device: device, shots: shots, captions: rows.map { $0.2 }, names: rows.map { "\($0.0)_\($0.1)" },
                  out: "\(base)/\(locale)/\(device)-frise")
        count += 1
    }
}
print("\(count) frises produites")
