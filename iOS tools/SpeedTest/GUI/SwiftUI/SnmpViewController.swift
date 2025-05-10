//
//  SnmpViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 06/04/2025.
//  Copyright © 2025 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

class SnmpViewController : UIViewController {
    private lazy var hostingViewController = makeHostingController()

    private func makeHostingController() -> UIHostingController<SNMPTreeView> {
        let hostingController = UIHostingController(rootView: SNMPTreeView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }

    /*
    public func addTrace(_ content: String, level: LogLevel = .ALL, date: Date? = nil) {
        if Thread.current.isMainThread == false {
            print("warning: addTrace not called from main thread")
        }
        hostingViewController.rootView.model.append(content, level: level, date: date)
    }
     */

    // For this to work, we must set "View controller-based status bar appearance" to true in Plist
    // See also "Status bar is initially hidden" in Plist
    override var prefersStatusBarHidden: Bool {
        return true
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
