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

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
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
        barItemToButton.removeAll()
        for barItem in items {
            let button = UIButton(type: .system)
            button.setImage(barItem.image, for: .normal)
            button.tintColor = barItem.tintColor ?? COLORS.leftpannel_bottombar_buttons
            button.isEnabled = barItem.isEnabled
            if let target = barItem.target, let action = barItem.action {
                button.addTarget(target, action: action, for: .touchUpInside)
            }
            button.widthAnchor.constraint(equalToConstant: 36).isActive = true
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            stackView.addArrangedSubview(button)
            barItemToButton.append((barItem, button))
        }

        // Start a timer to sync dynamic properties (enabled, tintColor) from bar items to buttons
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.syncBarItemProperties()
        }

        container.addSubview(stackView)
        view.addSubview(container)
        view.bringSubviewToFront(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: UIDevice.current.userInterfaceIdiom == .pad ? view.bottomAnchor : view.safeAreaLayoutGuide.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 44),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        customToolbarView = container
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

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
            if stackView.arrangedSubviews.count != currentItems.count, !currentItems.isEmpty {
                stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                barItemToButton.removeAll()
                for barItem in currentItems {
                    let button = UIButton(type: .system)
                    button.setImage(barItem.image, for: .normal)
                    button.tintColor = barItem.tintColor ?? COLORS.leftpannel_bottombar_buttons
                    button.isEnabled = barItem.isEnabled
                    if let target = barItem.target, let action = barItem.action {
                        button.addTarget(target, action: action, for: .touchUpInside)
                    }
                    button.widthAnchor.constraint(equalToConstant: 36).isActive = true
                    button.heightAnchor.constraint(equalToConstant: 36).isActive = true
                    stackView.addArrangedSubview(button)
                    barItemToButton.append((barItem, button))
                }
            }
        }
    }
}
