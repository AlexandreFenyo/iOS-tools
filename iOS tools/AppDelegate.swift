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
import Network
import CoreData
import iOSToolsMacros

let isAppResilient = Bundle.main.object(forInfoDictionaryKey: "Resilient") as! Bool

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // The app delegate must implement the window property if it wants to use a main storyboard file
    var window: UIWindow?

    var persistentContainer: NSPersistentContainer?

    private var local_chargen_service: NetService?
    private var local_chargen_service_delegate: LocalGenericDelegate<SpeedTestChargenClient>?
    private var local_discard_service: NetService?
    private var local_discard_service_delegate: LocalGenericDelegate<SpeedTestDiscardClient>?
    private var local_app_service: NetService?
    private var local_app_service_delegate: LocalGenericDelegate<SpeedTestAppClient>?
    
    private var local_chargen_listener: NetworkServiceListener?

    private var masterViewController: MasterViewController?
    private var tracesViewController: TracesViewController?
    
    // Check that the service is published with: dig -p 5353 @192.168.0.170 _speedtestapp._tcp.local. PTR
    private func startChargenService() {
        if let local_chargen_service_delegate {
            local_chargen_service_delegate.timer!.invalidate()
        }
        
        local_chargen_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_chargen_service_type, name: "", port: Int32(NetworkDefaults.speed_test_chargen_port))
        local_chargen_service_delegate = LocalGenericDelegate<SpeedTestChargenClient>(manage_input: true, manage_output: true, master_view_controller: masterViewController)
        local_chargen_service_delegate!.restartService = startChargenService
        local_chargen_service!.delegate = local_chargen_service_delegate
        local_chargen_service!.publish(options: .listenForConnections)
    }
    
    private func startDiscardService() {
        if let local_discard_service_delegate {
            local_discard_service_delegate.timer!.invalidate()
        }

        local_discard_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_discard_service_type, name: "", port: Int32(NetworkDefaults.speed_test_discard_port))
        local_discard_service_delegate = LocalGenericDelegate<SpeedTestDiscardClient>(manage_input: true, manage_output: false, master_view_controller: masterViewController)
        local_discard_service_delegate!.restartService = startDiscardService
        local_discard_service!.delegate = local_discard_service_delegate
        local_discard_service!.publish(options: .listenForConnections)
    }
    
    private func startAppService() {
        if let local_app_service_delegate {
            local_app_service_delegate.timer!.invalidate()
        }

        local_app_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_app_service_type, name: "", port: Int32(NetworkDefaults.speed_test_app_port))
        local_app_service_delegate = LocalGenericDelegate<SpeedTestAppClient>(manage_input: true, manage_output: false, master_view_controller: masterViewController)
        local_app_service_delegate!.restartService = startAppService
        local_app_service!.delegate = local_app_service_delegate
        local_app_service!.publish(options: .listenForConnections)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // The following line is a trick: this forces the initialization of DBMaster.shared at the start of the app, therefore this calls addNode() for default nodes at the start of the app even if it not necessary. Otherwise, when we debug the app starting on the Network panel, the default nodes would not appear before going to the Discover panel.
        _ = DBMaster.shared

        // We do not call #saveTrace("main: application started") since we do not want to display the file name and line number
        Traces.addMessage("main: application started")
        
        InitTCPPort2Service()
        
        guard
            let tabBarController = window?.rootViewController as? UITabBarController,
            let splitViewController = tabBarController.viewControllers?.first as? SplitViewController,
            let leftNavController = splitViewController.viewControllers.first as? LeftNavController,
            let masterViewController = leftNavController.topViewController as? MasterViewController,
            let rightNavController = splitViewController.viewControllers.last as? RightNavController,
            let detailViewController = rightNavController.topViewController as? DetailViewController,
            let tracesViewController = tabBarController.viewControllers?[2] as? TracesViewController
            // May be useful for debugging:
            //,
            // let intermanViewController = tabBarController.viewControllers?[1] as? IntermanViewController
            // let devices = masterViewController.devices[.localGateway]
        else { fatalError(#saveTrace("application")) }

        guard let intermanViewController = tabBarController.viewControllers?[1] as? IntermanViewController
        else { fatalError(#saveTrace("application / intermanViewController")) }

        // May be useful for debugging:
        // Set the first device displayed in the detail view controller:
        // detailViewController.device = devices.first
        
        // May be useful for debugging:
        // Suppress the third view controller (Traces) to get a MVP (Minimum Viable Product)
        // tabBarController.viewControllers?.remove(at: 2)

        // May be useful for debugging:
        // Select the Network tab as the default one, to debug faster
        // tabBarController.selectedIndex = 1
        
        self.masterViewController = masterViewController
        
        self.masterViewController!.detail_view_controller = detailViewController
        self.masterViewController!.detail_navigation_controller = rightNavController
        self.masterViewController!.split_view_controller = splitViewController
        self.masterViewController!.traces_view_controller = tracesViewController
        self.masterViewController!.interman_view_controller = intermanViewController

        detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        detailViewController.master_view_controller = masterViewController
        intermanViewController.master_view_controller = masterViewController
        intermanViewController.hostingViewController.rootView.master_view_controller = masterViewController

        // Placeholder for some tests
        if GenericTools.must_call_initial_tests { GenericTools.test(masterViewController: masterViewController) }
        
        // Start local services - utilise une API obsolete mais l'API Network a un bug sur le REUSEADDR, donc on préfère cette API obsolète mais non buggée
        startChargenService()
        startDiscardService()
        startAppService()
        
        // Start browsing for remote services
        masterViewController.browser_app = ServiceBrowser(NetworkDefaults.speed_test_app_service_type, deviceManager: masterViewController)

//        for svcname in [ "_airplay._tcp.", "_airport._tcp." ] {
        for svcname in service_names {
            masterViewController.browsers.append(ServiceBrowser(svcname, deviceManager: masterViewController))
        }
        
//        let svcname = "_airplay._tcp.";
//        masterViewController.browsers.append(ServiceBrowser(svcname, deviceManager: masterViewController))
//        masterViewController.browsers.append(ServiceBrowser("_ssh._tcp.", deviceManager: masterViewController))
//        masterViewController.browsers.append(ServiceBrowser("_dns-sd._udp.", deviceManager: masterViewController))

        
        // idem avec API Network Bonjour de Network car ancienne est déprecative - à conserver pour le moment où elle ne fonctionnera plus - mais cette API pose aussi des pbs même en mettant le soreuseaddr: il ne marche pas à tous les coups, et c'est plus embêtant car il faut attendre plus longtemps pour refaire un listener qui fonctionne, plusieurs secondes, voire de 10 à 20 secondes
        // mais pas utile, il suffisait de rajouter dans Info.plist :
        // <key>NSLocalNetworkUsageDescription</key>
        //   <string>Network usage is required for macOS/iOS communication</string>
        //   <key>NSBonjourServices</key>
        //   <array>
        //     <string>_ssh._tcp</string>
        //     <string>_speedtestchargen._tcp</string>
        //     <string>_speedtestdiscard._tcp</string>
        //   </array>
        // https://developer.apple.com/forums/thread/129465
        // https://developer.apple.com/forums/thread/662869
        /*
         let params = NWParameters()
         let browser = NWBrowser(for: .bonjour(type: "_speedtestchargen._tcp" /*"_ssh._tcp"*/, domain: "local"), using: params)
         browser.stateUpdateHandler = { newState in
         switch newState {
         case .failed(let error):
         browser.cancel()
         // Handle restarting browser
         print("XXXXX: Browser - failed with %{public}@, restarting", error.localizedDescription)
         case .ready:
         print("XXXXX: Browser - ready")
         case .setup:
         print("XXXXX: Browser - setup")
         default:
         break
         }
         }
         browser.browseResultsChangedHandler = { results, changes in
         for result in results {
         print("XXXXX: Browser - found matching endpoint with %{public}@", result.endpoint.debugDescription)
         // Send endPoint back on a delegate to set up a NWConnection for sending/receiving data
         break
         }
         }
         // Start browsing and ask for updates on the main queue.
         browser.start(queue: .main)
         */
        
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

     masterViewController?.navigationController!.tabBarController?.tabBar.barTintColor = COLORS.tabbar_bg
     masterViewController?.navigationController!.tabBarController?.tabBar.backgroundColor = COLORS.tabbar_bg

        if UserDefaults.standard.bool(forKey: "reset_help_popups_key") {
            UserDefaults.standard.set(false, forKey: "reset_help_popups_key")
            let settings = UserDefaults.standard.dictionaryRepresentation()
            for foo in settings {
                if foo.key.starts(with: "help.") {
                    UserDefaults.standard.set(false, forKey: foo.key)
                }
            }
        }
        
        Task.detached { @MainActor in
            // Note: The UserDefaults class is thread-safe (https://developer.apple.com/documentation/foundation/userdefaults)
            if UserDefaults.standard.bool(forKey: "remove_nodes_key") {
                UserDefaults.standard.set(false, forKey: "remove_nodes_key")
                UserDefaults.standard.set([String](), forKey: "nodes")
                await self.masterViewController?.resetToDefaultHosts()
                self.masterViewController?.updateLocalNodeAndGateways()
            }
            
            await self.masterViewController?.detail_view_controller?.applicationDidBecomeActive()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // Main thread
    override init() {
        // call super.init() to be able to use self
        super.init()
        //        GenericTools.here("init()", self)

        // Since we run in the main thread, the Data Store context is associated to the main thread
        let container = NSPersistentContainer(name: "ToolsDataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                // Do not log this error using #fatalError() nor #saveTrace() because it would not be saved, since the persistant store is not loaded
                print("Unable to load persistent stores: \(error)")
            } else {
                self.persistentContainer = container
            }
        }
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
