//
//  TracesViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

// différents moyens de communications du modèle :
// https://developer.apple.com/documentation/swiftui/state-and-data-flow

import Foundation

import UIKit
import SwiftUI

public class TracesViewModel : ObservableObject {
    @Published private(set) var traces: String

    init(traces: String) {
        self.traces = traces
    }
    
    public func update(str: String) {
        traces = str
    }
}

public var model = TracesViewModel(traces: "externe ")

class TracesViewController : UIViewController {
    private lazy var hostingViewController = makeHeader()

    private func makeHeader() -> UIHostingController<TracesSwiftUIView> {
//        let contentView = TracesSwiftUIView()
        let contentView = TracesSwiftUIView(model: model, txt: "création")
        
        print("on crée la vue SwiftUI", contentView)
        
        let contentVC = UIHostingController(rootView: contentView)
        contentVC.view.translatesAutoresizingMaskIntoConstraints = false
        return contentVC
    }

    public func addTrace(_ content: String) {
        print("TracesViewController.addTrace()", content)
        
//        hostingViewController.rootView.txt = "FGRIOJOKFEOZKFZEOFK"
//        print("on tape sur ", hostingViewController.rootView)
        
        print("ICI")
//        hostingViewController.rootView.model = TracesViewModel(traces: "TEST")
        hostingViewController.rootView.txt = "ABCDEF"
        hostingViewController.rootView.model.update(str: "IEFRZHJEFJRZEFIR")

        
        //        viewModel.update(str: content)
        //hostingViewController.rootView.model = TracesViewModel(traces: "TEST")

        // marche pas mais devrait marcher...
        // hostingViewController.rootView = TracesSwiftUIView(contr: self)
        // hostingViewController.rootView.model = TracesViewModel(traces: "ERRRRRR")
        // utilité ?: hostingViewController.loadView()

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
