//
//  AppDelegate.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit
import SwiftUI
import ModelIO


extension UIApplication {}

@UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {
    // The app delegate must implement the window property if it wants to use a main storyboard file
    public var window: UIWindow?

    private var local_chargen_service: NetService?
    private var local_discard_service: NetService?
    private var masterViewController : MasterViewController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        guard
            let splitViewController = window?.rootViewController as? SplitViewController,
            let leftNavController = splitViewController.viewControllers.first as? LeftNavController,
            let masterViewController = leftNavController.topViewController as? MasterViewController,
            let rightNavController = splitViewController.viewControllers.last as? RightNavController,
            let detailViewController = rightNavController.topViewController as? DetailViewController
            else { fatalError() }
        
        self.masterViewController = masterViewController

        masterViewController.detail_view_controller = detailViewController
        masterViewController.detail_navigation_controller = rightNavController
        masterViewController.split_view_controller = splitViewController

        detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        detailViewController.master_view_controller = masterViewController
        return true
    }

}
