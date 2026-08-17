//
//  compose-screenshots.swift — composition des captures App Store
//
//  Ajoute un bandeau de texte EN HAUT de chaque capture brute (le texte des captures
//  est OCRisé et indexé par Apple, et seul le haut est visible dans la vignette des
//  résultats de recherche), et produit un PNG sans canal alpha aux dimensions exactes
//  exigées par App Store Connect.
//
//  Usage :  swift scripts/compose-screenshots.swift [répertoire-screenshots]
//
//  Lit scripts/screenshot-captions.tsv (locale, langue simulateur, index, scénario,
//  légende avec \n pour les retours à la ligne) et, pour chaque entrée et chaque
//  appareil, compose :
//    <dir>/raw/<langue>/<appareil>/<scénario>.png
//  vers
//    <dir>/<locale>/<appareil>/<index>_<scénario>.png
//
import AppKit
import Foundation

let script_url = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
let root = script_url.deletingLastPathComponent().deletingLastPathComponent()
let base = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : root.appendingPathComponent("ASO/screenshots")

// Dimensions exigées par App Store Connect (portrait)
let sizes: [String: NSSize] = [
    "iphone69": NSSize(width: 1320, height: 2868),
    "ipad13": NSSize(width: 2064, height: 2752),
]

let band_ratio = 0.16          // hauteur du bandeau texte, en fraction de la hauteur
let bg = NSColor(srgbRed: 0.043, green: 0.106, blue: 0.169, alpha: 1)   // #0B1B2B
let corner_radius = 40.0

func compose(raw: URL, caption: String, size: NSSize, out: URL) throws {
    guard let shot = NSImage(contentsOf: raw) else {
        throw NSError(domain: "compose", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "illisible : \(raw.path)"])
    }
    let band = size.height * band_ratio
    let img = NSImage(size: size)
    img.lockFocus()

    bg.setFill()
    NSRect(origin: .zero, size: size).fill()

    // Capture ajustée en hauteur sous le bandeau, centrée, coins arrondis
    let avail = size.height - band * 1.08
    let scale = avail / shot.size.height
    let w = shot.size.width * scale
    let rect = NSRect(x: (size.width - w) / 2, y: size.height - band * 1.04 - avail,
                      width: w, height: avail)
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: corner_radius, yRadius: corner_radius).addClip()
    shot.draw(in: rect)
    NSGraphicsContext.current?.restoreGraphicsState()

    // Bandeau : vrai texte, gros, contrasté (indexé par Apple)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineHeightMultiple = 1.08
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size.width * 0.052, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: para,
    ]
    let inset = size.width * 0.06
    let text = NSAttributedString(string: caption, attributes: attrs)
    let text_height = text.boundingRect(
        with: NSSize(width: size.width - 2 * inset, height: band),
        options: [.usesLineFragmentOrigin]).height
    text.draw(in: NSRect(x: inset, y: size.height - (band + text_height) / 2,
                         width: size.width - 2 * inset, height: text_height))

    img.unlockFocus()

    // PNG sans alpha (exigence App Store Connect) : rendu dans un bitmap opaque
    guard let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let ctx = CGContext(data: nil,
                              width: Int(size.width), height: Int(size.height),
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else { throw NSError(domain: "compose", code: 2) }
    ctx.draw(cg, in: CGRect(origin: .zero, size: size))
    guard let flat = ctx.makeImage() else { throw NSError(domain: "compose", code: 3) }
    let rep = NSBitmapImageRep(cgImage: flat)
    rep.size = size
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "compose", code: 4)
    }
    try FileManager.default.createDirectory(at: out.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    try data.write(to: out)
}

// Lecture du TSV
let tsv = try String(contentsOf: root.appendingPathComponent("scripts/screenshot-captions.tsv"),
                     encoding: .utf8)
var count = 0, missing = 0
for line in tsv.split(separator: "\n").dropFirst() {
    let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    guard f.count >= 5 else { continue }
    let (locale, sim_language, index, scenario) = (f[0], f[1], f[2], f[3])
    let caption = f[4].replacingOccurrences(of: "\\n", with: "\n")
    for (dev, size) in sizes {
        let raw = base.appendingPathComponent("raw/\(sim_language)/\(dev)/\(scenario).png")
        let out = base.appendingPathComponent("\(locale)/\(dev)/\(index)_\(scenario).png")
        guard FileManager.default.fileExists(atPath: raw.path) else {
            print("manquant : \(raw.path)")
            missing += 1
            continue
        }
        try compose(raw: raw, caption: caption, size: size, out: out)
        count += 1
    }
}
print("\(count) captures composées" + (missing > 0 ? ", \(missing) brutes manquantes" : ""))
