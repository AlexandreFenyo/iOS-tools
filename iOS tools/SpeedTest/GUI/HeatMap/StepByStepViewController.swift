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
class StepByStepViewController: UIViewController {
//    private var my_memory_tracker = MyMemoryTracker("HeatMapViewController")

    public var master_view_controller: MasterViewController?
    private lazy var hosting_view_controller = makeHostingController()

    #if targetEnvironment(macCatalyst)
    // Sous Mac Catalyst (iOS 26), le sélecteur d'onglets n'est pas dans la hiérarchie UIKit :
    // le système l'installe dans la NSToolbar de la fenêtre (NSToolbarTabBarTabItemsItemIdentifier).
    // Une présentation plein écran ne le recouvre donc pas : on masque la toolbar pendant que ce
    // modal est affiché, et on la restaure à sa fermeture. Au lancement, la NSToolbar peut ne pas
    // encore exister quand viewDidAppear est appelé : on réessaie brièvement.
    private var toolbar_hide_task: Task<Void, Never>?

    private func setWindowToolbarVisible(_ visible: Bool) {
        toolbar_hide_task?.cancel()
        toolbar_hide_task = nil
        if visible {
            view.window?.windowScene?.titlebar?.toolbar?.isVisible = true
        } else {
            toolbar_hide_task = Task { @MainActor [weak self] in
                for _ in 0..<20 {
                    if Task.isCancelled { return }
                    if let toolbar = self?.view.window?.windowScene?.titlebar?.toolbar {
                        toolbar.isVisible = false
                        return
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setWindowToolbarVisible(false)
    }
    #endif
    
    private func makeHostingController() -> UIHostingController<StepByStepSwiftUIView> {
        let hosting_view_controller = UIHostingController(rootView: StepByStepSwiftUIView(self))
        hosting_view_controller.view.translatesAutoresizingMaskIntoConstraints = false
        hosting_view_controller.modalPresentationStyle = .overCurrentContext
        return hosting_view_controller
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)
        setWindowToolbarVisible(true)
        #endif
        hosting_view_controller.rootView.cleanUp()
        if exporting_map == true {
            exporting_map = false
            let dialogMessage = UIAlertController(title: "Warning", message: "You have dismissed the heat map high resolution computation, it will continue in the background, check your photo roll in about one minute to find the exported map.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            dialogMessage.addAction(action)
            master_view_controller!.parent!.present(dialogMessage, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // dès cette ligne on n'a plus de deinit de ce view controller
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
