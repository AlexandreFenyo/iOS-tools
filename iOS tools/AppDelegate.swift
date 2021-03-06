//
//  AppDelegate.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit

extension UIApplication {
    // Find the status bar view
    var status_bar_view: UIView? {
        if responds(to: Selector(("statusBar"))) {
            return value(forKey: "statusBar") as? UIView
        }
        return nil
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // The app delegate must implement the window property if it wants to use a main storyboard file
    public var window: UIWindow?

    private var local_chargen_service: NetService?
    private var local_chargen_service_delegate: LocalGenericDelegate<SpeedTestChargenClient>?
    private var local_discard_service: NetService?
    private var local_discard_service_delegate: LocalGenericDelegate<SpeedTestDiscardClient>?
    private var browser_chargen: ServiceBrowser?
    private var browser_discard: ServiceBrowser?
    private var masterViewController : MasterViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        guard
            let tabBarController = window?.rootViewController as? UITabBarController,
            let splitViewController = tabBarController.viewControllers?.first as? SplitViewController,
            let leftNavController = splitViewController.viewControllers.first as? LeftNavController,
            let masterViewController = leftNavController.topViewController as? MasterViewController,
            let rightNavController = splitViewController.viewControllers.last as? RightNavController,
            let detailViewController = rightNavController.topViewController as? DetailViewController
//            let devices = masterViewController.devices[.localGateway]
            else { fatalError() }

        // Set the first device displayed in the detail view controller
//        detailViewController.device = devices.first

        self.masterViewController = masterViewController

        masterViewController.detail_view_controller = detailViewController
        masterViewController.detail_navigation_controller = rightNavController
        masterViewController.split_view_controller = splitViewController

        detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        
        // Customize status bar
        UIApplication.shared.status_bar_view?.backgroundColor = .black





        // Placeholder for some tests
        if GenericTools.must_call_initial_tests { GenericTools.test(masterViewController: masterViewController) }

        // Start local services
        local_chargen_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_chargen_service_type, name: "", port: Int32(NetworkDefaults.speed_test_chargen_port))
        local_chargen_service_delegate = LocalGenericDelegate<SpeedTestChargenClient>(manage_input: true, manage_output: true)
        local_chargen_service!.delegate = local_chargen_service_delegate
        local_chargen_service!.publish(options: .listenForConnections)

        local_discard_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_discard_service_type, name: "", port: Int32(NetworkDefaults.speed_test_discard_port))
        local_discard_service_delegate = LocalGenericDelegate<SpeedTestDiscardClient>(manage_input: true, manage_output: false)
        local_discard_service!.delegate = local_discard_service_delegate
        local_discard_service!.publish(options: .listenForConnections)

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
//        GenericTools.here("init()", self)
    }

}

// Example: changing the tab bar height
//public var tabbar_height: CGFloat?
//extension UITabBar {
//    override open func sizeThatFits(_ size: CGSize) -> CGSize {
//        var sizeThatFits = super.sizeThatFits(size)
//        if let h = tabbar_height { sizeThatFits.height = h }
//        else { sizeThatFits.height = 80 }
//        return sizeThatFits
//    }
//}
