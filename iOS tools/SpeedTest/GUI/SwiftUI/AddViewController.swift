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

// Si on veut changer la taille de ce view controller : https://stackoverflow.com/questions/54737884/changing-the-size-of-a-modal-view-controller

@MainActor
class AddViewController: UIViewController {
    public weak var master_view_controller: MasterViewController?
    
    //    @IBOutlet weak var view1: SKView!
    //    @IBOutlet weak var view2: UIView!
    
    private lazy var hosting_view_controller = makeHostingController()
    
    private func makeHostingController() -> UIHostingController<AddSwiftUIView> {
        let hosting_view_controller = UIHostingController(rootView: AddSwiftUIView(add_view_controller: self))
        hosting_view_controller.view.translatesAutoresizingMaskIntoConstraints = false
        hosting_view_controller.modalPresentationStyle = .overCurrentContext
        return hosting_view_controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(hosting_view_controller)
        view.addSubview(hosting_view_controller.view)
        hosting_view_controller.didMove(toParent: self)

        // nécessaire pour que les vues SwiftUI s'élargissent quand la vue UIKit s'élargit
         NSLayoutConstraint.activate([
            hosting_view_controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting_view_controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting_view_controller.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hosting_view_controller.view.heightAnchor.constraint(equalTo: view.heightAnchor)
         ])
    }
}
