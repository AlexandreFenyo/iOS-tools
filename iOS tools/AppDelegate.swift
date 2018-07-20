//
//  AppDelegate.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    private var local_chargen_service: NetService?
    private var local_chargen_service_delegate: LocalChargenDelegate?
    private var browser_chargen: ServiceBrowser?
    private var browser_discard: ServiceBrowser?
    private var masterViewController : MasterViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Log
        GenericTools.here("application()", self)

        guard let splitViewController = window?.rootViewController as? SplitViewController,
            let leftNavController = splitViewController.viewControllers.first as? UINavigationController,
            let masterViewController = leftNavController.topViewController as? MasterViewController,
            let rightNavController = splitViewController.viewControllers.last as? UINavigationController,
            let detailViewController = rightNavController.topViewController as? DetailViewController,
            let devices = masterViewController.devices[.localGateway]
            else { fatalError() }

        // Set the first device displayed in the detail view controller
        detailViewController.device = devices.first

        self.masterViewController = masterViewController

        masterViewController.detail_view_controller = detailViewController
        masterViewController.detail_navigation_controller = rightNavController
        masterViewController.split_view_controller = splitViewController

        detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem

        // Placeholder for some tests
        if GenericTools.must_call_initial_tests { GenericTools.test() }

        // Start local services
        local_chargen_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_chargen_service_type, name: "", port: NetworkDefaults.speed_test_chargen_port)
        local_chargen_service_delegate = LocalChargenDelegate()
        local_chargen_service!.delegate = local_chargen_service_delegate
        local_chargen_service!.publish(options: .listenForConnections)

        // Start browsing for remote services
        // We can test easily to browse using _ssh._tcp.
        browser_chargen = ServiceBrowser(NetworkDefaults.speed_test_chargen_service_type, deviceManager: masterViewController)
        browser_discard = ServiceBrowser(NetworkDefaults.speed_test_discard_service_type, deviceManager: masterViewController)
        masterViewController.browser_chargen = browser_chargen
        masterViewController.browser_discard = browser_discard

        return true
    }

    // Tester ce qui se passe si le bg vient d'un appel tél reçu

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        masterViewController?.applicationWillResignActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    override init() {
        // call super.init() to be able to use self
        super.init()
        GenericTools.here("init()", self)
    }

}

