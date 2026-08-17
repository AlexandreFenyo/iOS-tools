//
//  ReviewRequester.swift
//  iOS tools
//
//  Politique de demande d'avis App Store.
//
//  Remplace la constante globale `disable_request_reviews`, qui était déclarée dans
//  SNMPView.swift — un fichier sans rapport — et qui neutralisait silencieusement les
//  quatre sites d'appel. Résultat : environ 61 notes pour ~2 500 ventes.
//
//  Apple limite les invites à 3 par utilisateur et par période de 365 jours ; au-delà
//  l'appel est ignoré sans erreur. Il faut donc ne demander qu'après une réussite, et
//  jamais après une erreur.
//
//  Created by Alexandre Fenyo.
//

import Foundation
import StoreKit
import UIKit

@MainActor
final class ReviewRequester {
    static let shared = ReviewRequester()
    private init() {}

    /// Interrupteur de secours pour le débogage local.
    static let disabled = false

    private enum Key {
        static let completed_maps = "review.completed_heatmaps"
        static let last_prompt_date = "review.last_prompt_date"
        static let last_prompt_version = "review.last_prompt_version"
    }

    /// Nombre de heat maps exportées avec succès avant la première invite.
    private let min_completed_maps = 2

    /// Délai minimal entre deux invites, quelle que soit la version.
    private let min_interval: TimeInterval = 90 * 24 * 3600

    private var current_version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    /// À appeler uniquement quand une heat map a été enregistrée sans erreur.
    func recordHeatMapCompleted() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: Key.completed_maps) + 1, forKey: Key.completed_maps)
    }

    private func shouldRequest() -> Bool {
        if Self.disabled { return false }
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: Key.completed_maps) >= min_completed_maps else { return false }
        // Une invite au maximum par version.
        if defaults.string(forKey: Key.last_prompt_version) == current_version { return false }
        if let last = defaults.object(forKey: Key.last_prompt_date) as? Date,
           Date().timeIntervalSince(last) < min_interval { return false }
        return true
    }

    /// Demande l'avis si la politique l'autorise. `scene` doit être la fenêtre active.
    /// À appeler après la fermeture de toute alerte : iOS ignore l'invite si un autre
    /// contrôleur modal est en cours de présentation.
    func requestIfAppropriate(in scene: UIWindowScene?) {
        guard shouldRequest(), let scene else { return }
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: Key.last_prompt_date)
        defaults.set(current_version, forKey: Key.last_prompt_version)
        AppStore.requestReview(in: scene)
    }

    /// Point d'entrée manuel, pour un bouton « Noter l'application ».
    /// Contrairement à `requestIfAppropriate`, cette URL fonctionne toujours et ne
    /// consomme aucun des trois créneaux annuels accordés par Apple.
    static var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id1662393654?action=write-review")!
    }
}
