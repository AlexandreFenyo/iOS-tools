//
//  DetailViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 02/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit
import SpriteKit
import SwiftUI
class MySKSceneDelegate : NSObject, SKSceneDelegate {
//    public var nodes : [SKChartNode] = []

    /*
    public func update(_ currentTime: TimeInterval, for scene: SKScene) {
        for n in nodes { n.updateWidth() }
    }*/
}

@MainActor
class DetailViewController: UIViewController {

    private lazy var hostingViewController = makeHostingController()

    private func makeHostingController() -> UIHostingController<DetailSwiftUIView> {
        let hostingController = UIHostingController(rootView: DetailSwiftUIView(view: view))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)

//        hostingViewController.rootView.pingloop?.start(ts: hostingViewController.rootView.ts)
        
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
    
    // called by MasterViewController when the user selects an address
    public func addressSelected(_ address: IPAddress) {
        print("set current_node")
        // ICI que le bug se produit
        hostingViewController.rootView.model.setNodeAddress()
    }
   
    // you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
