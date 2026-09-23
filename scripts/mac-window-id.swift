//
//  mac-window-id.swift — identifiant de la fenêtre principale d'un processus
//
//  Usage : swift scripts/mac-window-id.swift <pid>
//  Affiche le numéro de la plus grande fenêtre visible (couche 0) du processus,
//  à passer à `screencapture -l`. Code de sortie 1 si aucune fenêtre n'est trouvée.
//  Utilisé par scripts/screenshots.sh pour les captures Mac Catalyst.
//
import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 2, let pid = Int32(CommandLine.arguments[1]) else {
    FileHandle.standardError.write("usage: mac-window-id.swift <pid>\n".data(using: .utf8)!)
    exit(2)
}

let infos = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
    as? [[String: Any]] ?? []

let best = infos
    .filter { ($0[kCGWindowOwnerPID as String] as? Int32) == pid && ($0[kCGWindowLayer as String] as? Int) == 0 }
    .max { a, b in
        func area(_ w: [String: Any]) -> CGFloat {
            let r = w[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
            return (r["Width"] ?? 0) * (r["Height"] ?? 0)
        }
        return area(a) < area(b)
    }

guard let window = best, let number = window[kCGWindowNumber as String] as? Int else { exit(1) }
print(number)
