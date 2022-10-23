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
    
    private lazy var hosting_view_controller = makeHostingController()
    
    private func makeHostingController() -> UIHostingController<AddSwiftUIView> {
        let hosting_view_controller = UIHostingController(rootView: AddSwiftUIView(view: view))
        hosting_view_controller.view.translatesAutoresizingMaskIntoConstraints = false
//        hosting_view_controller.modalPresentationStyle = .overCurrentContext
        return hosting_view_controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // utile sur iPhone, pour pouvoir revenir en arrière depuis la vue avec le chart
        //        navigationItem.leftItemsSupplementBackButton = true
        
        //        hostingViewController.view.backgroundColor = COLORS.right_pannel_bg
        
        addChild(hosting_view_controller)
        view.addSubview(hosting_view_controller.view)
        hosting_view_controller.didMove(toParent: self)
        
//        tabBarController!.present(self, animated: false)
        
//        present(hostingViewController, animated: false)
        
        
        let ref_frame = parent!.view.frame
      let w : CGFloat = 600
    let h : CGFloat = 400
  view.frame = CGRectMake(ref_frame.width/2 - w/2, ref_frame.height/2 - h/2, w, h)

//        view.frame = CGRectMake(200, 200, 200, 200)

        
        //        view2.addSubview(hostingViewController.view)
        
//       hosting_view_controller.didMove(toParent: self)
        
        // nécessaire pour que les vues SwiftUI s'élargissent quand la vue UIKit s'élargit

        /*
        NSLayoutConstraint.activate([
            hosting_view_controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting_view_controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting_view_controller.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hosting_view_controller.view.heightAnchor.constraint(equalTo: view.heightAnchor)
         ])
        */
        //        view1.presentScene(scene)
    }
    
}
