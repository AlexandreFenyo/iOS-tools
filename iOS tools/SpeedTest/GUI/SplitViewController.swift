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
        preferredDisplayMode = .allVisible

        self.delegate = self
    }

    // On iPad, when in multi applications at once mode, the app may be in a compact trait and, in such a case, the status bar is replaced by another bar type without any background color. Therefore, the navigation bar background color is used, so the black rounded edges must not be displayed. In order to avoid having to check if we are in a multi applications at once mode, we choose to hide the rounded edges when the application is in a compact trait, even when not in application at once mode.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // as? and not as!: depending on the state of the app, the first and last controllers may not both being set
        if let left_nav_view_controller = viewControllers.first as? LeftNavController {
            left_nav_view_controller.rv!.isHidden = traitCollection.horizontalSizeClass == .compact
        }
        if let right_nav_view_controller = viewControllers.last as? RightNavController {
            right_nav_view_controller.rv!.isHidden = traitCollection.horizontalSizeClass == .compact
        }
    }

//    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewControllerDisplayMode {
//        print("BUTTON EXPAND APPUYE")
//        print(displayMode.rawValue)
//        if 1 == displayMode.rawValue {
//            print("SUPPRESSION DE LA BARRE")
//            tabbar_height = 0
//            // marche pas
//            tabbarViewController!.view.setNeedsDisplay()
//            tabbarViewController!.view.layoutIfNeeded()
//            tabbarViewController!.view.setNeedsLayout()
//            tabbarViewController!.view.setNeedsDisplay()
//            for vc in tabbarViewController!.viewControllers! {
//                vc.view.setNeedsDisplay()
//                vc.view.setNeedsLayout()
//                vc.view.layoutSubviews()
//                vc.view.layoutIfNeeded()
//                vc.view.setNeedsDisplay()
//                vc.view.setNeedsLayout()
//                vc.view.layoutSubviews()
//                vc.view.layoutIfNeeded()
//            }
//        }
//        if 2 == displayMode.rawValue {
//            print("REMISE DE LA BARRE")
//            tabbar_height = nil
//            // marche pas
//            tabbarViewController!.view.setNeedsDisplay()
//            tabbarViewController!.view.setNeedsLayout()
//            tabbarViewController!.view.layoutIfNeeded()
//            tabbarViewController!.view.setNeedsDisplay()
//            for vc in tabbarViewController!.viewControllers! {
//                vc.view.setNeedsDisplay()
//                vc.view.setNeedsLayout()
//                vc.view.layoutSubviews()
//                vc.view.layoutIfNeeded()
//                vc.view.setNeedsDisplay()
//                vc.view.setNeedsLayout()
//                vc.view.layoutSubviews()
//                vc.view.layoutIfNeeded()
//            }
//        }
//        return .automatic
//    }
    
    // Update status bar style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillLayoutSubviews() {
//        preferredPrimaryColumnWidthFraction = 0.3
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

            print("SplitViewController.prepare(for segue)")
    }

}
