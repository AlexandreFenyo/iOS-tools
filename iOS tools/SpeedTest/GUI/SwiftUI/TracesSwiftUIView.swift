//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

// https://useyourloaf.com/blog/adapting-swiftui-label-style/
struct AdaptiveLabelStyle: LabelStyle {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  func makeBody(configuration: Configuration) -> some View {
    if horizontalSizeClass == .compact {
      VStack {
        configuration.icon
          if UIDevice.current.userInterfaceIdiom != .phone {
              configuration.title
          }
      }
    } else {
      Label(configuration)
    }
  }
}

public class TracesViewModel : ObservableObject {
    static let shared = TracesViewModel()
    
    // Libellés complétés à 5 caractères pour que le texte qui suit soit aligné
    // (la fonte des traces est à chasse fixe sur Mac). Non traduits : les boutons de niveau
    // filtrent l'affichage sur « [<libellé>] » (cf. levelFilter), dans toutes les langues
    static let log_level_to_string: [LogLevel: String] = [
        LogLevel.INFO: "INFO ",
        LogLevel.DEBUG: "DEBUG",
        LogLevel.ALL: "ALL  "
    ]

    // Texte de filtre qui ne retient que les traces d'un niveau : « [INFO ] », « [DEBUG] »,
    // « [ALL  ] » — les crochets écartent les traces d'un autre niveau dont le texte
    // contiendrait le mot
    static func levelFilter(_ level: LogLevel) -> String { "[" + log_level_to_string[level]! + "]" }
    
    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    
    // Contrainte à respecter : il faut toujours au moins 1 chaîne dans traces
    // le 7 mars 2023 : Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates. => identifier pourquoi et corriger
    // Idem le 15 juin
    @Published private(set) var traces: [String] = {
        var arr = [String]()
        arr.append("")
        #if DEBUG
        // Captures App Store : journal fictif à la place des vraies traces (noms d'hôtes,
        // adresses, historique des sessions précédentes rechargé depuis Core Data)
        if DemoMode.enabled {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let start = Calendar.current.date(bySettingHour: 9, minute: 38, second: 0, of: Date()) ?? Date()
            let labels: [LogLevel: String] = [.INFO: "INFO ", .DEBUG: "DEBUG", .ALL: "ALL  "]
            for t in DemoMode.traces {
                arr.append(df.string(from: start.addingTimeInterval(TimeInterval(t.seconds)))
                           + " [" + labels[t.level]! + "]: " + t.text)
            }
            return arr
        }
        #endif
        for i in 1...200 {
//                arr.append("Speed Test - Traces zfeiopjf oifj o jefozi jeofjioj ei jozefij ezoi jezo ijezo ijezoi ejzfo jzeo jzefi oezfj ziefo jzeo ijzef oizejfoize jfezo ijzefo ijzef ozefj zieo jezio jzeoi jzeofi jezo ijzeoi jzeoi jzeoi jezo ijzeo ijzeo ijzeio jzeio j \(i)")
//                arr.append("Speed Test - Traces \(i)")
        }
        return arr
    }()
    
    fileprivate func clear() {
        traces = [ "" ]
        Traces.deleteMessages()
    }
    
    public func append(_ str: String, level _level: LogLevel = .ALL, date _date: Date? = nil) {
        #if DEBUG
        if DemoMode.enabled { return }
        #endif
        // Toutes les traces sont conservées, quel que soit leur niveau : les boutons de niveau
        // ne font que filtrer l'affichage
        traces.append(df.string(from: _date ?? Date()) + " [" + Self.log_level_to_string[_level]! + "]: " + str)
    }
}

public enum LogLevel : Int {
    case INFO = 0
    case DEBUG
    case ALL
}

// Contrôleur permettant aux boutons SwiftUI de piloter le défilement du UITextView
@MainActor
final class TracesScrollController {
    fileprivate weak var text_view: UITextView?

    fileprivate func scrollToTop() {
        guard let text_view else { return }
        text_view.setContentOffset(CGPoint(x: 0, y: -text_view.adjustedContentInset.top), animated: true)
    }

    fileprivate func scrollToBottom() {
        guard let text_view else { return }
        let y = text_view.contentSize.height - text_view.bounds.height + text_view.adjustedContentInset.bottom
        text_view.setContentOffset(CGPoint(x: 0, y: max(y, -text_view.adjustedContentInset.top)), animated: true)
    }
}

// Les traces sont affichées dans un UITextView natif en lecture seule plutôt que dans des
// Text SwiftUI : on bénéficie ainsi des gestes classiques de sélection et de copie (glisser
// à la souris sur Mac, poignées de sélection sur iOS, menu contextuel, Cmd-A/Cmd-C), y
// compris sur une sélection à cheval sur plusieurs lignes.
fileprivate struct TracesTextView: UIViewRepresentable {
    let traces: [String]
    let filter: String
    @Binding var locked: Bool
    let controller: TracesScrollController

    // SF Mono : la déclinaison à chasse fixe de San Francisco, sur toutes les plates-formes
    private static let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .regular),
        .foregroundColor: COLORS.standard_background.darker().darker()
    ]

    // Les occurrences du filtre sont mises en gras dans les lignes affichées
    private static let bold_attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .bold),
        .foregroundColor: COLORS.standard_background.darker().darker()
    ]

    // Une ligne de trace, avec les occurrences du filtre en gras (même comparaison,
    // insensible à la casse, que le filtrage lui-même)
    private static func attributedLine(_ line: String, filter: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: line, attributes: attributes)
        guard !filter.isEmpty else { return result }
        var search_range = line.startIndex..<line.endIndex
        while let match = line.range(of: filter, options: [.caseInsensitive], range: search_range, locale: .current) {
            result.addAttributes(bold_attributes, range: NSRange(match, in: line))
            search_range = match.upperBound..<line.endIndex
        }
        return result
    }

    private static func attributedText<S: Sequence>(_ traces: S, filter: String, leading_newline: Bool) -> NSAttributedString where S.Element == String {
        let result = NSMutableAttributedString()
        var first = !leading_newline
        for trace in traces {
            if !first {
                result.append(NSAttributedString(string: "\n", attributes: attributes))
            }
            first = false
            result.append(attributedLine(trace, filter: filter))
        }
        return result
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let text_view = UITextView()
        text_view.isEditable = false
        text_view.isSelectable = true
        text_view.backgroundColor = .clear
        text_view.alwaysBounceVertical = true
        text_view.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        text_view.delegate = context.coordinator
        return text_view
    }

    func updateUIView(_ text_view: UITextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        controller.text_view = text_view

        if traces.count > coordinator.applied_count, coordinator.applied_count > 0,
           filter == coordinator.applied_filter,
           traces[coordinator.applied_count - 1] == coordinator.applied_last {
            // Cas courant : de nouvelles traces ajoutées à la fin — on n'ajoute que le suffixe,
            // sans réécrire tout le texte, pour préserver une éventuelle sélection en cours
            text_view.textStorage.append(Self.attributedText(traces[coordinator.applied_count...], filter: filter, leading_newline: true))
        } else if traces.count != coordinator.applied_count || traces.last != coordinator.applied_last
                    || filter != coordinator.applied_filter {
            // Réécriture complète (premier affichage, traces effacées ou filtre modifié)
            text_view.attributedText = Self.attributedText(traces, filter: filter, leading_newline: false)
        } else {
            return
        }
        coordinator.applied_count = traces.count
        coordinator.applied_last = traces.last
        coordinator.applied_filter = filter

        // Suivi automatique de la fin des traces
        if locked {
            DispatchQueue.main.async { [weak controller] in
                controller?.scrollToBottom()
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TracesTextView
        var applied_count = 0
        var applied_last: String?
        var applied_filter = ""

        init(_ parent: TracesTextView) {
            self.parent = parent
        }

        // L'utilisateur commence à faire défiler : on suspend le suivi automatique de la fin
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            if parent.locked {
                DispatchQueue.main.async { self.parent.locked = false }
            }
        }

        // Revenu en bas de la liste : on reprend le suivi automatique
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate { checkBottom(scrollView) }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            checkBottom(scrollView)
        }

        private func checkBottom(_ scrollView: UIScrollView) {
            let bottom_offset = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
            if scrollView.contentOffset.y >= bottom_offset - 1, !parent.locked {
                DispatchQueue.main.async { self.parent.locked = true }
            }
        }
    }
}

struct TracesSwiftUIView: View {
    @ObservedObject var model = TracesViewModel.shared

    @State public var locked = true
    @State private var scroll_controller = TracesScrollController()
    @State private var filter = ""

    // Bouton de niveau : remplace le filtre par « [<niveau>] » (n'affiche que les traces de ce
    // niveau) ; un nouvel appui sur le bouton actif efface le filtre. Il est en surbrillance
    // tant que le filtre est exactement le sien.
    private func levelButton(_ level: LogLevel, _ title: LocalizedStringKey, systemImage: String) -> some View {
        let level_filter = TracesViewModel.levelFilter(level)
        let active = filter == level_filter
        return Button {
            filter = active ? "" : level_filter
        } label: {
            Label(title, systemImage: systemImage)
                .labelStyle(AdaptiveLabelStyle())
                .foregroundColor(active ? Color.white.lighter() : Color.gray)
                .padding(12)
                .font(.footnote)
        }
        .background(active ? COLORS.tabbar_bg5 : Color(COLORS.standard_background).darker().darker())
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
    }

    var body: some View {
        ZStack {
            TracesTextView(traces: filter.isEmpty ? model.traces :
                            model.traces.filter { $0.localizedCaseInsensitiveContains(filter) },
                           filter: filter, locked: $locked, controller: scroll_controller)

            VStack {
                HStack(alignment: .top) {
                    // Le fixedSize horizontal contraint ce VStack à sa largeur idéale, dictée
                    // par la rangée de boutons ; le champ de filtre (maxWidth: .infinity)
                    // s'étire alors exactement à cette largeur
                    VStack(alignment: .leading) {
                        HStack {
                            levelButton(.INFO, "INFO", systemImage: "rectangle.split.2x2")

                            levelButton(.DEBUG, "DEBUG", systemImage: "tablecells")

                            levelButton(.ALL, "ALL", systemImage: "rectangle.split.3x3")
                        }
                        .lineLimit(1)

                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.gray)
                            ZStack(alignment: .leading) {
                                if filter.isEmpty {
                                    // Placeholder gris, comme les boutons de niveau non sélectionnés
                                    Text("Filter traces")
                                        .font(.footnote)
                                        .foregroundColor(Color.gray)
                                        .allowsHitTesting(false)
                                }
                                TextField("", text: $filter)
                                    .textFieldStyle(.plain)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .font(.footnote)
                                    .foregroundColor(Color.white.lighter())
                            }
                            // Largeur idéale nulle : sous le fixedSize du VStack parent, le champ prend
                            // la largeur de la rangée de boutons au lieu de s'élargir avec le texte saisi
                            .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity, alignment: .leading)
                            if !filter.isEmpty {
                                Button {
                                    filter = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color(COLORS.standard_background).darker().darker())
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    Spacer()

                    Button {
                        locked = false
                        scroll_controller.scrollToTop()
                    } label: {
                        Image("arrow up")
                            .renderingMode(.template)
                            .foregroundColor(.gray).padding(12)
                    }
                    .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))

                    Button {
                        locked = true
                        scroll_controller.scrollToBottom()
                    } label: {
                        Image("arrow down")
                            .renderingMode(.template)
                            .foregroundColor(locked ? Color.white : .gray)
                            .padding(12)
                    }
                    .background(Color(COLORS.standard_background).darker().darker())
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))

                    Button {
                        model.clear()
                    } label: {
                        Image(systemName: "delete.left.fill")
                            .renderingMode(.template)
                            .foregroundColor(.gray).padding(12)
                    }
                    .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))

                }.background(Color.clear)

                Spacer()
            }
            .padding() // Pour que les boutons en haut ne soient pas trop proches des bords de l'écran
        }
        .background(Color(COLORS.right_pannel_bg))
    }
}
