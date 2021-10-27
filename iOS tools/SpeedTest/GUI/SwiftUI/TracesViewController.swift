//
//  TracesViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import Foundation

import UIKit
import SwiftUI

class TracesViewModel {
    private var model: String

    init(model: String) {
        self.model = model
    }
}
extension TracesViewModel {
    var title: String {
        return model
    }
    func update(str: String) {
        model = str
    }
}

class TracesViewController : UIViewController {
    private let viewModel = TracesViewModel(model: "initstring")
    private lazy var hostingViewController = makeHeader()

    private func makeHeader() -> UIHostingController<TracesSwiftUIView> {
        let contentView = TracesSwiftUIView(content: "totot")
        let contentVC = UIHostingController(rootView: contentView)
        contentVC.view.translatesAutoresizingMaskIntoConstraints = false
        return contentVC
    }

    @State private var content2: String = ""
    private var contentView : UIHostingController<TracesSwiftUIView>!

    public func addTrace(_ content: String) {
        print("TracesViewController.addTrace()", content)
        viewModel.update(str: content)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: 1.0)
        ])
    }
}
