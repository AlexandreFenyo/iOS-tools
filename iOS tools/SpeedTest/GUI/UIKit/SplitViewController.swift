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
        if UIDevice.current.userInterfaceIdiom == .phone {
            // We run on an iPhone
            return true
        } else  {
            // We run on an iPad, therefore this method is called when the app goes to background. Therefore a collapse happens, so we need to avoid to incorporate the secondary view (right nav) into the collapsed interface. If we do not do that, the IP list appears on the right view when the user returns in the app.
            // A side effect is that if the app is first opened as a split app with another one on the screen, therefore the first view will be the right nav one. This is not the default behaviour expected when opening the app in a compact size, like on an iPad or on a splitted app with another on an iPad screen. But it only has effects on iPad with the app splited, therefore this is for advanced users and they only have to click on the back icon at the top of the screen to go back to the nodes list.
            return false
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
