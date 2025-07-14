//
//  SnmpViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 06/04/2025.
//  Copyright © 2025 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

@MainActor
class SnmpViewController: UIViewController {
    weak var master_view_controller: MasterViewController? = nil

    private lazy var hostingViewController = makeHostingController()

    private func makeHostingController() -> UIHostingController<AnyView> {
        let current_selected_target_simple = (UIApplication.shared.delegate as! AppDelegate).current_selected_target_simple
        
        let rootView = AnyView(SNMPView(master_view_controller: master_view_controller!).environmentObject(current_selected_target_simple))
        
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }

    // For this to work, we must set "View controller-based status bar appearance" to true in Plist
    // See also "Status bar is initially hidden" in Plist
    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)

//        hostingViewController.view.backgroundColor = .blue //COLORS.right_pannel_bg

        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
}
