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
class DetailViewController: UIViewController {
    public var master_view_controller: MasterViewController?
    @IBOutlet weak var view2: UIView!
    
    private lazy var hostingViewController = makeHostingController()

    private func makeHostingController() -> UIHostingController<DetailSwiftUIView> {
        let hostingController = UIHostingController(rootView: DetailSwiftUIView(view: view, master_view_controller: master_view_controller!))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // utile sur iPhone, pour pouvoir revenir en arrière depuis la vue avec le chart
        navigationItem.leftItemsSupplementBackButton = true

        addChild(hostingViewController)
        view2.addSubview(hostingViewController.view)

        hostingViewController.didMove(toParent: self)

        // nécessaire pour que les vues SwiftUI s'élargissent quand la vue UIKit s'élargit
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view2.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view2.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view2.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(equalTo: view2.heightAnchor)
        ])
    }
    
    public func setText(_ str: String) {
        print("setText() dans DetailViewController: : \(str)")
//        DispatchQueue.main.async {
            let _ = self.hostingViewController.rootView.model.setText(str)
  //      }
    }
    
    public func enableButtons(_ state: Bool) {
        // ce dispatch est obligatoire sinon on écrase le modèle par un simple accès à hostingViewController.rootView.model
        // il est async pour éviter une exception
        DispatchQueue.main.async {
            let _ = self.hostingViewController.rootView.model.setButtonsEnabled(state)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
    }

    override func viewDidDisappear(_ animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("DetailViewController.prepare(for segue)")
    }
    
    
    
}
