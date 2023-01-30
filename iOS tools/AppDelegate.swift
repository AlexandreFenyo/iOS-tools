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

// extension UIApplication {}

// bug : je lance un update et je passe dans l'onglet traces et je reviens une fois qu'il y a des nouveaux noeuds => exception

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // The app delegate must implement the window property if it wants to use a main storyboard file
    public var window: UIWindow?
    
    public var local_chargen_service: NetService?
    public var local_chargen_service_delegate: LocalGenericDelegate<SpeedTestChargenClient>?
    public var local_discard_service: NetService?
    public var local_discard_service_delegate: LocalGenericDelegate<SpeedTestDiscardClient>?
    public var local_app_service: NetService?
    public var local_app_service_delegate: LocalGenericDelegate<SpeedTestAppClient>?
    
    private var local_chargen_listener: NetworkServiceListener?

    // private var browser_chargen: ServiceBrowser?
    // private var browser_discard: ServiceBrowser?
    // private var browser_app: ServiceBrowser?
    
    private var masterViewController : MasterViewController?
    private var tracesViewController : TracesViewController?
    
    // pour tester la publication : dig -p 5353 @192.168.0.170 _speedtestapp._tcp.local. PTR
    public func startChargenService() {
        if let local_chargen_service_delegate {
            local_chargen_service_delegate.timer!.invalidate()
        }
        
        local_chargen_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_chargen_service_type, name: "", port: Int32(NetworkDefaults.speed_test_chargen_port))
        local_chargen_service_delegate = LocalGenericDelegate<SpeedTestChargenClient>(manage_input: true, manage_output: true)
        local_chargen_service_delegate!.restartService = startChargenService
        local_chargen_service!.delegate = local_chargen_service_delegate
        local_chargen_service!.publish(options: .listenForConnections)
    }
    
    public func startDiscardService() {
        if let local_discard_service_delegate {
            local_discard_service_delegate.timer!.invalidate()
        }

        local_discard_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_discard_service_type, name: "", port: Int32(NetworkDefaults.speed_test_discard_port))
        local_discard_service_delegate = LocalGenericDelegate<SpeedTestDiscardClient>(manage_input: true, manage_output: false)
        local_discard_service_delegate!.restartService = startDiscardService
        local_discard_service!.delegate = local_discard_service_delegate
        local_discard_service!.publish(options: .listenForConnections)
    }
    
    public func startAppService() {
        if let local_app_service_delegate {
            local_app_service_delegate.timer!.invalidate()
        }

        local_app_service = NetService(domain: NetworkDefaults.local_domain_for_browsing, type: NetworkDefaults.speed_test_app_service_type, name: "", port: Int32(NetworkDefaults.speed_test_app_port))
        local_app_service_delegate = LocalGenericDelegate<SpeedTestAppClient>(manage_input: true, manage_output: false)
        local_app_service_delegate!.restartService = startAppService
        local_app_service!.delegate = local_app_service_delegate
        local_app_service!.publish(options: .listenForConnections)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        InitTCPPort2Service()
        
        guard
            let tabBarController = window?.rootViewController as? UITabBarController,
            let splitViewController = tabBarController.viewControllers?.first as? SplitViewController,
            let leftNavController = splitViewController.viewControllers.first as? LeftNavController,
            let masterViewController = leftNavController.topViewController as? MasterViewController,
            let rightNavController = splitViewController.viewControllers.last as? RightNavController,
            let detailViewController = rightNavController.topViewController as? DetailViewController,
            let tracesViewController = tabBarController.viewControllers?[1] as? TracesViewController /* ,
                                                                                                      let consoleViewController = tabBarController.viewControllers?[2] */
                //            let devices = masterViewController.devices[.localGateway]
        else { fatalError() }
        
        // Set the first device displayed in the detail view controller
        //        detailViewController.device = devices.first
        
        // suppression du 3ième view controller (console) pour le MVP
        tabBarController.viewControllers?.remove(at: 2)
        
        self.masterViewController = masterViewController
        
        masterViewController.detail_view_controller = detailViewController
        masterViewController.detail_navigation_controller = rightNavController
        masterViewController.split_view_controller = splitViewController
        masterViewController.traces_view_controller = tracesViewController
        
        detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        detailViewController.master_view_controller = masterViewController
        
        // Placeholder for some tests
        if GenericTools.must_call_initial_tests { GenericTools.test(masterViewController: masterViewController) }
        
        // Start local services - utilise une API obsolete mais l'API Network a un bug sur le REUSEADDR, donc on préfère cette API obsolète mais non buggée
        startChargenService()
        startDiscardService()
        startAppService()
        
        // Start browsing for remote services
        // We can test easily to browse using _ssh._tcp.
        // browser_chargen = ServiceBrowser(NetworkDefaults.speed_test_chargen_service_type, deviceManager: masterViewController)
        // browser_discard = ServiceBrowser(NetworkDefaults.speed_test_discard_service_type, deviceManager: masterViewController)
        // masterViewController.browser_chargen = browser_chargen
        // masterViewController.browser_discard = browser_discard

        masterViewController.browser_app = ServiceBrowser(NetworkDefaults.speed_test_app_service_type, deviceManager: masterViewController)

        let svcname = "_airplay._tcp.";
        masterViewController.browsers.append(ServiceBrowser(svcname, deviceManager: masterViewController))
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
        
        if UserDefaults.standard.bool(forKey: "reset_help_popups_key") {
            UserDefaults.standard.set(false, forKey: "reset_help_popups_key")
            let settings = UserDefaults.standard.dictionaryRepresentation()
            for foo in settings {
                if foo.key.starts(with: "help.") {
                    UserDefaults.standard.set(false, forKey: foo.key)
                }
            }
        }
        
        if UserDefaults.standard.bool(forKey: "remove_nodes_key") {
            UserDefaults.standard.set(false, forKey: "remove_nodes_key")
            UserDefaults.standard.set([], forKey: "nodes")
            masterViewController?.resetToDefaultHosts()
            masterViewController?.updateLocalNodeAndGateways()
        }
        
        masterViewController?.detail_view_controller?.applicationDidBecomeActive()
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
