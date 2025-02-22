//
//  TracesViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

// différents moyens de communications du modèle :
// https://developer.apple.com/documentation/swiftui/state-and-data-flow

import SwiftUI

class TracesViewController : UIViewController {
    private lazy var hostingViewController = makeHostingController()

    private func makeHostingController() -> UIHostingController<TracesSwiftUIView> {
        let hostingController = UIHostingController(rootView: TracesSwiftUIView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }

    public func addTrace(_ content: String, level: LogLevel = .ALL, date: Date? = nil) {
        if Thread.current.isMainThread == false {
            print("warning: addTrace not called from main thread")
        }
        hostingViewController.rootView.model.append(content, level: level, date: date)
    }

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
