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

class TracesViewModel {
    public var traces: String

    init(traces: String) {
        // appelé à chaque fois qu'on tape sur le bouton en haut à droite dans la vue SwiftUI
        self.traces = traces
    }
}
extension TracesViewModel {
    var title: String {
        return traces
    }
    func update(str: String) {
        print("updateX(",str,")")
//        traces += str
          
    }
}

class TracesViewController : UIViewController {
    private lazy var hostingViewController = makeHeader()

    private func makeHeader() -> UIHostingController<TracesSwiftUIView> {
//        let contentView = TracesSwiftUIView()
        let contentView = TracesSwiftUIView(txt: "création", contr: self)
        
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
        hostingViewController.rootView.model = TracesViewModel(traces: "TEST")
        
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
