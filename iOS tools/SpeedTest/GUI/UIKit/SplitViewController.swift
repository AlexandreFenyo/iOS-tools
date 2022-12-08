//
//  ViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 02/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Pour avoir l'icône d'agrandissement dans le detail view controller (icone "expand")
        preferredDisplayMode = .oneBesideSecondary

        self.delegate = self
    }

    // On iPad, when in multi applications at once mode, the app may be in a compact trait and, in such a case, the status bar is replaced by another bar type without any background color. Therefore, the navigation bar background color is used, so the black rounded edges must not be displayed. In order to avoid having to check if we are in a multi applications at once mode, we choose to hide the rounded edges when the application is in a compact trait, even when not in application at once mode.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // as? and not as!: depending on the state of the app, the first and last controllers may not both being set
        /* SUPPRIME POUR LE MVP
        if let left_nav_view_controller = viewControllers.first as? LeftNavController {
            left_nav_view_controller.rv?.isHidden = traitCollection.horizontalSizeClass == .compact
        }
        if let right_nav_view_controller = viewControllers.last as? RightNavController {
            right_nav_view_controller.rv?.isHidden = traitCollection.horizontalSizeClass == .compact
        }
         */
    }

    override func viewWillLayoutSubviews() {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // On iPhone, show the primary view controller's view by default
    // https://stackoverflow.com/questions/25875618/uisplitviewcontroller-in-portrait-on-iphone-shows-detail-vc-instead-of-master
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
