//
//  MyTabBarController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 06/11/2024.
//  Based on https://stackoverflow.com/questions/78631030/how-to-disable-the-new-uitabbarcontroller-view-style-in-ipados-18

import Foundation
import UIKit

class MyTabBarController: UITabBarController {
    // Active for iPads running iOS 18+ where the traditional tab bar has been removed by Apple
    lazy var alternateTabBarActive: Bool = {
    #if compiler(>=6.0) // Compiler flag for Xcode >= 16
        if #available(iOS 26.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            // iOS 26+ has a redesigned tab bar at the top; hide the legacy bottom tab bar
            self.tabBar.isHidden = true
            self.tabBar.alpha = 0
            self.tabBar.frame = .zero
            return false
        } else if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            self.isTabBarHidden = true
            return true
        }
    #endif
        return false
    }()

    var tabBarHeightConstraint: NSLayoutConstraint?

    // MARK: - Sélecteur d'onglets personnalisé (iPad et Mac Catalyst, iOS 26+)
    // Piste "icônes + libellés" : pilule jaune, un bouton icône+libellé par onglet,
    // sélection en pastille beige. Le sélecteur système (barre flottante iOS 26 /
    // NSToolbar Catalyst) est masqué. Sur iPhone, la tab bar native est conservée.
    private var custom_top_bar: UIView?
    private var custom_tab_buttons: [UIButton] = []
    private var custom_tab_titles: [String] = []

    private var use_custom_top_bar: Bool {
        if #available(iOS 26.0, *), UIDevice.current.userInterfaceIdiom == .pad { return true }
        return false
    }

    private func setupCustomTopBar() {
        let bar = UIView()
        bar.backgroundColor = COLORS.leftpannel_topbar_bg
        bar.layer.cornerRadius = 20
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.layer.zPosition = 100

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        custom_tab_buttons.removeAll()
        custom_tab_titles.removeAll()
        for (index, vc) in (viewControllers ?? []).enumerated() {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.image = vc.tabBarItem.image?.withRenderingMode(.alwaysTemplate)
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            config.imagePadding = 6
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            button.configuration = config
            button.tag = index
            button.addTarget(self, action: #selector(customTabPressed(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
            custom_tab_buttons.append(button)
            if vc is IntermanViewController {
                // Libellé raccourci (« Vue 3D » au lieu de « Vue réseau 3D ») pour
                // limiter la largeur du bandeau, qui touchait la liste des cibles
                custom_tab_titles.append(NSLocalizedString("3D View", comment: "3D View"))
            } else {
                custom_tab_titles.append(vc.tabBarItem.title ?? vc.title ?? "")
            }
        }

        bar.addSubview(stack)
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 3),
            stack.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -3),
            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 3),
            stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -3),
            bar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6)
        ])
        custom_top_bar = bar
        updateCustomTopBarSelection()
    }

    @objc private func customTabPressed(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateCustomTopBarSelection()
    }

    private func updateCustomTopBarSelection() {
        // Pendant les transitions (présentation du modal de démarrage...), selectedIndex
        // peut être temporairement invalide : on garde alors l'état courant
        guard selectedIndex >= 0, selectedIndex < custom_tab_buttons.count else { return }
        for (index, button) in custom_tab_buttons.enumerated() {
            let selected = index == selectedIndex
            // Pastille de sélection posée sur le layer : le style .plain de
            // UIButton.Configuration écrase config.background
            button.backgroundColor = selected ? COLORS.chart_bg : .clear
            button.layer.cornerRadius = 17
            guard var config = button.configuration else { continue }
            config.baseForegroundColor = selected ? COLORS.standard_background : COLORS.standard_background.withAlphaComponent(0.75)
            if index < custom_tab_titles.count {
                config.attributedTitle = AttributedString(custom_tab_titles[index], attributes: AttributeContainer([
                    .font: UIFont.systemFont(ofSize: 13, weight: selected ? .semibold : .regular)
                ]))
            }
            button.configuration = config
        }
    }

    override var selectedViewController: UIViewController? {
        didSet { updateCustomTopBarSelection() }
    }

    #if targetEnvironment(macCatalyst)
    // Sous Catalyst, le sélecteur système vit dans la NSToolbar de la fenêtre :
    // masquée définitivement, le sélecteur personnalisé la remplace. La NSToolbar
    // peut ne pas encore exister au premier passage : on réessaie brièvement.
    private var toolbar_hide_started = false
    private func hideCatalystToolbar() {
        guard use_custom_top_bar, !toolbar_hide_started else { return }
        toolbar_hide_started = true
        Task { @MainActor [weak self] in
            for _ in 0..<20 {
                if let toolbar = self?.view.window?.windowScene?.titlebar?.toolbar {
                    toolbar.isVisible = false
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    #endif

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if targetEnvironment(macCatalyst)
        hideCatalystToolbar()
        #endif
    }

    lazy var alternateTabBar: UITabBar = {
        UITabBar()
    }()

    func getTabBar() -> UITabBar {
        return alternateTabBarActive ? alternateTabBar : tabBar
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if use_custom_top_bar {
            setupCustomTopBar()
            // Masque aussi la barre d'onglets flottante système (iPad iOS 26)
            if #available(iOS 18.0, *) {
                self.isTabBarHidden = true
            }
        }

        if self.alternateTabBarActive {
            self.tabBar.isHidden = true

            self.alternateTabBar.items = self.tabBar.items
            self.alternateTabBar.selectedItem = self.tabBar.selectedItem

            if UIDevice.current.userInterfaceIdiom == .pad {
                // Add Custom Tabbar
                let tabbar = self.alternateTabBar
                self.view.addSubview(tabbar)

                // Add layout constraints
                tabbar.translatesAutoresizingMaskIntoConstraints = false
                let bottom = tabbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                let leading = tabbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
                let trailing = tabbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                let height = NSLayoutConstraint(item: self.alternateTabBar, attribute: .height, relatedBy: .equal,
                                                toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1)
                self.tabBarHeightConstraint = height
                self.view.addConstraints([bottom, leading, trailing, height])
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if self.alternateTabBarActive {
            self.alternateTabBar.items = self.tabBar.items
            self.alternateTabBar.selectedItem = self.tabBar.selectedItem
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let bar = custom_top_bar {
            view.bringSubviewToFront(bar)
            updateCustomTopBarSelection()
        }

        if self.alternateTabBarActive {
            // Adjust height constraint
            let height = self.alternateTabBar.intrinsicContentSize.height
            self.tabBarHeightConstraint?.constant = height

            // Set insets for child view controllers
            let bottomInset = self.alternateTabBar.frame.size.height-self.view.safeAreaInsets.bottom
            self.viewControllers?.forEach { $0.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0) }
        }
    }

}
