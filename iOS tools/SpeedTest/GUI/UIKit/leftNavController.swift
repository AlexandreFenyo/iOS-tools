//
//  leftNavController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 17/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// https://medium.com/whoknows-swift/swift-the-hierarchy-of-uinavigationcontroller-programmatically-91631990f495
// https://www.raywenderlich.com/411-core-graphics-tutorial-part-1-getting-started
// https://cocoacasts.com/working-with-auto-layout-in-code

import Foundation
import UIKit

class LeftNavController : UINavigationController {
    let r : CGFloat = 20
//    var rv : RoundedCornerView? // SUPPRIME POUR LE MVP

    // Custom toolbar view for iOS 26+ where the built-in toolbar is broken in column-style UISplitViewController
    private var customToolbarView: UIView?
    // Mapping from original UIBarButtonItems to custom UIButtons for property sync
    private var barItemToButton: [(UIBarButtonItem, UIButton)] = []
    private var syncTimer: Timer?

    @objc
    func tapScrollView(_ sender: UITapGestureRecognizer) {
        let topRow = IndexPath(row: 0, section: 0)
        let masterViewController = topViewController as? MasterViewController
        masterViewController?.tableView.scrollToRow(at: topRow, at: .top, animated: true)
        let masterIPViewController = topViewController as? MasterIPViewController
        masterIPViewController?.tableView.scrollToRow(at: topRow, at: .top, animated: true)
    }

    // A partir de iOS 26, si dans Info.plist on ne positionne pas UIDesignRequiresCompatibility à YES, viewDidLoad n'est jamais appelée et on ne voit donc pas le LeftNavController
    override func viewDidLoad() {
        super.viewDidLoad()

        // Scroll to top when touching the top of screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapScrollView(_:)))
        navigationBar.addGestureRecognizer(tapGestureRecognizer)

        if #available(iOS 26.0, *) {
            setupiOS26Toolbar()
        } else {
            setupLegacyToolbar()
        }

        // Manage the navigation bar behaviour
        // pour éviter les problèmes avec iOS15 : https://developer.apple.com/forums/thread/682420
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = COLORS.leftpannel_topbar_bg
        // Sous Mac Catalyst, le titre est rendu par défaut avec un effet de vibrance
        // qui le fait apparaître en mélange de bleu et de noir sur notre fond opaque.
        // Fixer explicitement la couleur désactive cet effet ; sans incidence sur les
        // autres plates-formes, où le titre est déjà noir (style Light forcé).
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // Note : la compensation du rembourrage Liquid Glass (iOS 26) est calculée
        // dynamiquement dans viewDidLayoutSubviews — l'ancien -45 fixe faisait passer
        // la barre sous la Dynamic Island (iPhone), la barre d'état (iPad) et les
        // boutons de fenêtre (Mac Catalyst).
    }

    // Sous iOS 26, Liquid Glass ajoute un rembourrage excessif au-dessus de la barre
    // de navigation dans un UISplitViewController en colonnes. On retire uniquement
    // l'excédent au-delà de la safe area réelle de la fenêtre, jamais davantage :
    // la barre affleure ainsi la Dynamic Island / barre d'état / barre de titre sans
    // passer dessous. Le calcul converge : une fois l'excédent retiré, il vaut zéro.
    private func compensateLiquidGlassPadding() {
        guard #available(iOS 26.0, *) else { return }
        #if targetEnvironment(macCatalyst)
        // Pas de rembourrage excédentaire constaté sous Catalyst : ne rien retirer.
        #else
        let window_safe_top = view.window?.safeAreaInsets.top ?? 0
        let excess = navigationBar.frame.minY - window_safe_top
        if excess > 0.5 {
            additionalSafeAreaInsets.top -= excess
        }
        #endif
    }

    private func setupLegacyToolbar() {
        // Manage the toolbar background
        let h = toolbar.bounds.height
        let margin : CGFloat = 5
        let d = h - 2 * margin
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: h, height: h))
        let image1 = renderer.image { (context) in
            COLORS.toolbar_bg.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: margin, y: margin, width: d, height: d))
        }
        let image = image1.resizableImage(withCapInsets: UIEdgeInsets(top: h / 2, left: h / 2, bottom: h / 2, right: h / 2))
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        toolbar.addSubview(imageView)
        toolbar.sendSubviewToBack(imageView)

        // Manage constraints for auto resizing
        imageView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addConstraints(
            [
                NSLayoutConstraint(item: toolbar!, attribute: .leading, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar!, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar!, attribute: .trailing, relatedBy: .equal, toItem: imageView, attribute: .trailing, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: toolbar!, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])

        // Make the toolbar background transparent
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        // Remove the top border of the toolbar
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
    }

    @available(iOS 26.0, *)
    private func setupiOS26Toolbar() {
        // Hide the broken built-in toolbar
        setToolbarHidden(true, animated: false)

        // Create a plain UIView with buttons instead of UIToolbar to avoid Liquid Glass styling
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = COLORS.toolbar_bg

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 4

        // Find toolbar items: try topViewController first, then search through all child VCs
        let items: [UIBarButtonItem] = topViewController?.toolbarItems
            ?? viewControllers.compactMap({ $0.toolbarItems }).first(where: { !$0.isEmpty })
            ?? []
        populateToolbar(stackView, items: items)

        // Start a timer to sync dynamic properties (enabled, tintColor) from bar items to buttons
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.syncBarItemProperties()
        }

        container.addSubview(stackView)
        view.addSubview(container)
        view.bringSubviewToFront(container)
        // Ancrage au bas de la VUE sur toutes les plates-formes (jamais à la safe area,
        // que reserveCustomToolbarInset modifie : sur iPhone cet ancrage créait une
        // boucle de rétroaction de layout qui gelait le premier rendu ~15 s).
        // Sur iPhone la hauteur est étendue de l'inset système (indicateur home) par
        // reserveCustomToolbarInset ; les boutons restent dans les 44 pt supérieurs.
        let height_constraint = container.heightAnchor.constraint(equalToConstant: 44)
        custom_toolbar_height_constraint = height_constraint
        let bottom_constraint = container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        custom_toolbar_bottom_constraint = bottom_constraint
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom_constraint,
            height_constraint,
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
        customToolbarView = container
    }

    // Nombre d'items représentés par la barre personnalisée (les séparateurs et
    // groupes rendent arrangedSubviews.count inutilisable pour la comparaison)
    private var built_toolbar_item_count = 0

    // (Re)construit la barre : groupes séparés par de fins liserés
    // (navigation | actions sur la liste | réglages) quand la barre complète est affichée
    private func populateToolbar(_ stackView: UIStackView, items: [UIBarButtonItem]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        barItemToButton.removeAll()
        built_toolbar_item_count = items.count
        
        func makeButton(_ barItem: UIBarButtonItem) -> UIButton {
            let button = UIButton(type: .system)
            button.setImage(barItem.image, for: .normal)
            button.tintColor = barItem.tintColor ?? COLORS.leftpannel_bottombar_buttons
            button.isEnabled = barItem.isEnabled
            if let target = barItem.target, let action = barItem.action {
                button.addTarget(target, action: action, for: .touchUpInside)
            }
            button.widthAnchor.constraint(equalToConstant: 36).isActive = true
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            barItemToButton.append((barItem, button))
            return button
        }
        
        func makeSeparator() -> UIView {
            let separator = UIView()
            separator.backgroundColor = COLORS.standard_background.withAlphaComponent(0.35)
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
            separator.heightAnchor.constraint(equalToConstant: 22).isActive = true
            return separator
        }
        
        // Les items d'espacement (flexible/fixed space, sans image ni titre ni vue)
        // servaient à répartir les icônes dans la toolbar native : dans cette barre
        // personnalisée ils deviendraient des boutons vides — on les écarte
        let items = items.filter { $0.image != nil || $0.title != nil || $0.customView != nil }
        let groups: [[UIBarButtonItem]]
        var pack_left = false
        if items.count == 8 {
            // Liste des cibles : navigation | actions sur la liste | réglages, répartis
            groups = [Array(items[0...1]), Array(items[2...5]), Array(items[6...7])]
        } else if items.count == 4 {
            // Liste des IPs : [3 boutons] | séparateur | [configuration], alignés à gauche
            groups = [Array(items[0...2]), [items[3]]]
            pack_left = true
        } else {
            groups = [items]
        }
        stackView.distribution = pack_left ? .fill : .equalSpacing
        stackView.spacing = pack_left ? 10 : 4
        for (group_index, group) in groups.enumerated() {
            if group_index > 0 { stackView.addArrangedSubview(makeSeparator()) }
            let group_stack = UIStackView()
            group_stack.axis = .horizontal
            group_stack.spacing = 4
            group_stack.alignment = .center
            for barItem in group { group_stack.addArrangedSubview(makeButton(barItem)) }
            stackView.addArrangedSubview(group_stack)
        }
        if pack_left {
            // Une vue extensible en fin de pile pousse les groupes vers la gauche
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            stackView.addArrangedSubview(spacer)
        }
    }

    private func syncBarItemProperties() {
        for (barItem, button) in barItemToButton {
            button.isEnabled = barItem.isEnabled
            button.tintColor = barItem.tintColor ?? COLORS.leftpannel_bottombar_buttons
            if button.image(for: .normal) != barItem.image {
                button.setImage(barItem.image, for: .normal)
            }
        }
    }

    private var custom_toolbar_height_constraint: NSLayoutConstraint?
    private var custom_toolbar_bottom_constraint: NSLayoutConstraint?

    // La barre d'outils personnalisée iOS 26 (une simple UIView posée par-dessus le
    // contenu) ne participe pas à la safe area, contrairement à la toolbar native :
    // sans cette réservation, la dernière ligne des listes est masquée dessous.
    // ⚠️ Calcul en forme fermée, UNIQUEMENT à partir de constantes et des insets de
    // la FENÊTRE (indépendants de additionalSafeAreaInsets) : une première version
    // mesurait toolbar_view.frame, qui dépendait de la safe area que ce code modifie —
    // boucle de rétroaction de layout qui gelait le premier rendu ~15 s sur iPhone.
    private func reserveCustomToolbarInset() {
        guard let toolbar_view = customToolbarView else { return }
        let wanted: CGFloat
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Sur iPhone, la vue s'étend sous la tab bar native (et l'indicateur home) :
            // la barre est remontée de la part SYSTÈME de la safe area — le total mesuré
            // moins notre propre contribution, différence invariante qui ne crée donc
            // pas de rétroaction de layout (contrairement à un ancrage à la safe area)
            let system_bottom = view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom
            if abs((custom_toolbar_bottom_constraint?.constant ?? 0) + system_bottom) > 0.5 {
                custom_toolbar_bottom_constraint?.constant = -system_bottom
            }
            wanted = toolbar_view.isHidden ? 0 : 44
        } else {
            let system_bottom = view.window?.safeAreaInsets.bottom ?? 0
            wanted = toolbar_view.isHidden ? 0 : max(0, 44 - system_bottom)
        }
        if abs(additionalSafeAreaInsets.bottom - wanted) > 0.5 {
            additionalSafeAreaInsets.bottom = wanted
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // La UIToolbar native, masquée dans viewDidLoad, est réaffichée par iOS 26
        // lors du push d'un contrôleur portant des toolbarItems (constaté avec la
        // liste des IPs) et recouvre alors la barre personnalisée. setToolbarHidden
        // ne suffit pas (le système la réaffiche après la dernière passe de layout) :
        // on neutralise la vue elle-même, comme MyTabBarController le fait pour la
        // tab bar héritée
        if #available(iOS 26.0, *) {
            if !isToolbarHidden {
                setToolbarHidden(true, animated: false)
            }
            if toolbar.alpha != 0 || !toolbar.isHidden {
                toolbar.alpha = 0
                toolbar.isHidden = true
            }
        }

        compensateLiquidGlassPadding()
        reserveCustomToolbarInset()

        // Ensure custom toolbar stays on top of FloatingBarContainerView
        if let customToolbarView {
            view.bringSubviewToFront(customToolbarView)

            // Hide custom toolbar when the detail view is showing (compact/iPhone mode)
            let topHasItems = topViewController?.toolbarItems?.isEmpty == false
            customToolbarView.isHidden = !topHasItems
        }

        // Rebuild custom toolbar buttons if the toolbar items count changed
        if let customToolbarView, !customToolbarView.isHidden, let stackView = customToolbarView.subviews.first as? UIStackView {
            let currentItems: [UIBarButtonItem] = topViewController?.toolbarItems
                ?? viewControllers.compactMap({ $0.toolbarItems }).first(where: { !$0.isEmpty })
                ?? []
            if built_toolbar_item_count != currentItems.count, !currentItems.isEmpty {
                populateToolbar(stackView, items: currentItems)
            }
        }
    }
}
