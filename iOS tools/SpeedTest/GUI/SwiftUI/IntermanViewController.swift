//
//  TracesViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

@MainActor
class IntermanViewController : UIViewController {
    public weak var master_view_controller: MasterViewController?
    
    private var hostingViewController = {
        let hostingController = UIHostingController(rootView: Interman3DSwiftUIView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()
    
    // Not used - in case we use Interman2DSwiftUIView
    private func make2DHostingController() -> UIHostingController<Interman2DSwiftUIView> {
        let hostingController = UIHostingController(rootView: Interman2DSwiftUIView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
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
            hostingViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        // This creates a strong ref to the target
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SKChartNode.handleTap(_:))))
        // This creates a strong ref to the target
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(SKChartNode.handlePan(_:))))
        // This creates a strong ref to the target
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(SKChartNode.handlePinch(_:))))
    }
    
    @objc
    func handleTap(_ gesture: UITapGestureRecognizer) {
        print("\(#function)")
        
    }
    
    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        print("\(#function)")

        // gesture est passé par adresse, or on va y accéder dans une Task alors que sa valeur aura donc pu être modifiée, donc on copie sa valeur pour l'utiliser plus tard
        let gesture_state = gesture.state
        let point = gesture_state == .changed ? gesture.translation(in: gesture.view!) : nil


        hostingViewController.rootView.rotateCamera()

    }
    
    @objc
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        print("\(#function)")
    }
}
