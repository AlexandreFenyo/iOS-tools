//
//  DemoData.swift
//  iOS tools
//
//  Mode démo pour les captures d'écran App Store, compilé uniquement en Debug et
//  activé par l'argument de lancement -UIScreenshotMode (cf. scripts/screenshots.sh).
//
//  En mode démo, l'écran de heat map pas-à-pas n'a aucune dépendance réseau : le
//  chargen automatique vers le serveur public n'est pas lancé, un jeu de sondes
//  pré-rempli produit une carte reproductible, et le compteur affiche un débit figé.
//

#if DEBUG
import Foundation

enum DemoMode {
    static let enabled = ProcessInfo.processInfo.arguments.contains("-UIScreenshotMode")

    /// Scénario de capture : "heatmap" (carte terminée, défaut), "measure" (mesure en
    /// cours, carte partielle) ou "discover" (pas de modal pas-à-pas, liste des cibles).
    /// Se passe en argument : -UIScreenshotScenario measure
    static let scenario: String = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-UIScreenshotScenario"), i + 1 < args.count {
            return args[i + 1]
        }
        return "heatmap"
    }()

    /// Haut de l'échelle : 240 Mbit/s.
    static let max_scale: Float = 240_000_000

    /// Valeur figée du compteur et du curseur d'échelle.
    static let displayed_speed: Float = 187_400_000

    /// Sondes en coordonnées relatives (0...1) du plan, débit en bit/s.
    /// Disposition choisie pour une lecture immédiate : très bon débit près du
    /// routeur (bas-gauche), affaiblissement progressif vers le coin opposé —
    /// le dégradé traverse toute la rampe de couleurs sans dominer par une teinte.
    private static let probes: [(x: Float, y: Float, v: Float)] = [
        (0.22, 0.82, 232_000_000), (0.52, 0.86, 205_000_000), (0.78, 0.80, 150_000_000),
        (0.18, 0.58, 198_000_000), (0.50, 0.55, 141_000_000), (0.82, 0.52, 74_000_000),
        (0.24, 0.30, 118_000_000), (0.55, 0.26, 62_000_000), (0.80, 0.22, 27_000_000),
        (0.40, 0.10, 41_000_000),
    ]

    /// Convertit les sondes relatives en valeurs absolues pour une image donnée.
    static func values(width: Int, height: Int) -> [IDWValue<Float>] {
        probes.map {
            IDWValue<Float>(x: UInt16($0.x * Float(width)),
                            y: UInt16($0.y * Float(height)),
                            v: $0.v)
        }
    }
}
#endif
