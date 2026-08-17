//
//  WiFiSignalMonitor.swift
//  iOS tools
//
//  Niveau de signal WiFi réel, disponible uniquement dans la version Mac (Catalyst).
//
//  iOS n'expose aucune API publique de puissance de signal (cf. TN3111) : sur
//  iPhone/iPad la heat map se construit sur le débit et la latence. macOS, lui,
//  expose CoreWLAN : CWInterface fournit le RSSI (dBm), le bruit et le débit de
//  transmission de l'interface associée. Ce moniteur interroge l'interface WiFi
//  chaque seconde et publie les valeurs pour l'affichage.
//
//  Note : depuis macOS 14, la lecture du SSID/BSSID exige l'autorisation de
//  localisation ; le RSSI et le bruit, eux, restent lisibles sans autorisation.
//  On n'affiche donc que les valeurs radio, jamais le nom du réseau.
//

#if targetEnvironment(macCatalyst)

import Combine
import Foundation

@MainActor
final class WiFiSignalMonitor: ObservableObject {
    static let shared = WiFiSignalMonitor()

    // RSSI en dBm (typiquement -30 excellent ... -90 inutilisable), nil si pas de WiFi
    @Published private(set) var rssi: Int?
    // Bruit en dBm
    @Published private(set) var noise: Int?
    // Débit de transmission négocié, en Mbit/s
    @Published private(set) var transmit_rate: Double?

    private var timer: Timer?
    private var listeners = 0

    private init() {}

    /// Démarrage compté : chaque vue appelante appelle start() à l'apparition et
    /// stop() à la disparition ; le timer ne tourne que si au moins une vue écoute.
    func start() {
        listeners += 1
        guard timer == nil else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        listeners = max(0, listeners - 1)
        if listeners == 0 {
            timer?.invalidate()
            timer = nil
        }
    }

    private func refresh() {
        // Appels via CoreWLANShim.m : l'API CoreWLAN est presente sous Catalyst
        // mais ses en-tetes la declarent indisponible ; 0 = pas de valeur.
        let value = Int(wlan_rssi())
        rssi = value == 0 ? nil : value
        let noise_value = Int(wlan_noise())
        noise = noise_value == 0 ? nil : noise_value
        let rate = wlan_txrate()
        transmit_rate = rate == 0 ? nil : rate
    }

    /// Libellé compact, par ex. « −52 dBm » ou « — » sans WiFi.
    var rssiLabel: String {
        guard let rssi else { return "—" }
        return "\(rssi) dBm"
    }
}

import SwiftUI

// Badge compact affichant le signal WiFi réel (RSSI/bruit CoreWLAN), version Mac.
struct RSSIBadge: View {
    @ObservedObject private var monitor = WiFiSignalMonitor.shared

    private var color: Color {
        guard let rssi = monitor.rssi else { return .gray }
        switch rssi {
        case ..<(-75): return .red
        case ..<(-65): return .orange
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "wifi")
                .foregroundStyle(color)
            Text(monitor.rssiLabel)
                .font(.system(size: 12, weight: .bold).monospacedDigit())
            if let noise = monitor.noise {
                Text("noise \(noise) dBm")
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
        .help("Real WiFi signal strength, measured by macOS (CoreWLAN)")
    }
}

#endif
