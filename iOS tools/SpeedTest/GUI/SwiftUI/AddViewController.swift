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

@MainActor
class AddViewController: UIViewController {
    public var master_view_controller: MasterViewController?
    
    //    @IBOutlet weak var view1: SKView!
    //    @IBOutlet weak var view2: UIView!
    
    private lazy var hostingViewController = makeHostingController()
    
    private func makeHostingController() -> UIHostingController<AddSwiftUIView> {
        let hostingController = UIHostingController(rootView: AddSwiftUIView(view: view))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // utile sur iPhone, pour pouvoir revenir en arrière depuis la vue avec le chart
        //        navigationItem.leftItemsSupplementBackButton = true
        
        //        hostingViewController.view.backgroundColor = COLORS.right_pannel_bg
        
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)
        
        let ref_frame = parent!.view.frame
        let w : CGFloat = 600
        let h : CGFloat = 400
        view.frame = CGRectMake(ref_frame.width / 2 - w / 2, ref_frame.height / 2 - h / 2, w, h)

        
        //        view2.addSubview(hostingViewController.view)
        
        //        hostingViewController.didMove(toParent: self)
        
        // nécessaire pour que les vues SwiftUI s'élargissent quand la vue UIKit s'élargit
         NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor)
         ])
        
        //        view1.presentScene(scene)
    }
    
}
