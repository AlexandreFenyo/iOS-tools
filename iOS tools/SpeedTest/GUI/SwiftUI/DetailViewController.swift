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

class MySKSceneDelegate : NSObject, SKSceneDelegate {
    public var nodes : [SKChartNode] = []

    public func update(_ currentTime: TimeInterval, for scene: SKScene) {
        Task {
            for n in nodes { await n.updateWidth() }
        }
    }
}

@MainActor
class DetailViewController: UIViewController {
    public weak var master_view_controller: MasterViewController?
    
    private var chart_node : SKChartNode?
    private var scene_delegate : MySKSceneDelegate?

    public let ts = TimeSeries()

    public var prev_addr_selected = ""
    
    @IBOutlet weak var view1: SKView!
    @IBOutlet weak var view2: UIView!

     public var can_be_launched = true
    
    private lazy var hostingViewController = makeHostingController()

    private func makeHostingController() -> UIHostingController<DetailSwiftUIView> {
        let hostingController = UIHostingController(rootView: DetailSwiftUIView(view: view, master_view_controller: master_view_controller!))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }

    public func applicationDidBecomeActive() {
        Task {
            await chart_node?.applicationDidBecomeActive()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // utile sur iPhone, pour pouvoir revenir en arrière depuis la vue avec le chart
        navigationItem.leftItemsSupplementBackButton = true

        hostingViewController.view.backgroundColor = COLORS.right_pannel_bg
        
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

        let scene = SKScene(size: view1.bounds.size)
        // pour débugguer si taille mal ajustée
        scene.backgroundColor = COLORS.chart_view_bg

        scene_delegate = MySKSceneDelegate()
        scene.delegate = scene_delegate

        view1.presentScene(scene)

        Task {
            await chart_node = SKChartNode(ts: ts, full_size: view1.bounds.size, grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: COLORS.chart_bg, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: view1)
            scene.addChild(chart_node!)
            scene_delegate!.nodes.append(chart_node!)
            
            chart_node!.position = CGPoint(x: 0, y: 0)
            chart_node!.registerGestureRecognizers(view: view1)

            // view1.showsFPS = true
            // view1.showsQuadCount = true

        }

    }
    
    public func stopButtonWillAppear() {
        DispatchQueue.main.async {
            self.hostingViewController.rootView.model.setStopButtonEnabled(false)
        }
    }
    
    public func stopButtonWillDisappear() {
        DispatchQueue.main.async {
            self.hostingViewController.rootView.model.setStopButtonEnabled(true)
        }
    }

    public func scrollToTop() {
        DispatchQueue.main.async {
            self.hostingViewController.rootView.model.toggleScrollToTop()
        }

    }

    public func setButtonMasterHiddenState(_ state: Bool) {
        DispatchQueue.main.async {
            self.hostingViewController.rootView.model.setButtonMasterHiddenState(state)
        }
    }

    public func setButtonMasterIPHiddenState(_ state: Bool) {
        DispatchQueue.main.async {
            self.hostingViewController.rootView.model.setButtonMasterIPHiddenState(state)
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hostingViewController.rootView.model.setStopButtonEnabled(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hostingViewController.rootView.model.setStopButtonEnabled(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if chart_node != nil {
            chart_node!.scene!.view!.isPaused = false
        }
        can_be_launched = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if chart_node != nil {
            chart_node!.scene!.view!.isPaused = true
        }
    }

    // Clear chart and stop browsing if selected address changes
    private func clearChart(new_address: IPAddress) {
        if prev_addr_selected != new_address.toNumericString() {
            prev_addr_selected = new_address.toNumericString() ?? ""
            Task.detached(priority: .userInitiated) {
                await self.master_view_controller?.detail_view_controller?.ts.setUnits(units: .BANDWIDTH)
                await self.master_view_controller?.detail_view_controller?.ts.removeAll()
                await self.master_view_controller?.stopBrowsing(.OTHER_ACTION)

                // Start an automatic ping loop
                await self.master_view_controller?.stopBrowsing(.LOOP_ICMP)
                await self.master_view_controller?.loopICMP(new_address, display_timeout: false)
            }
        }
    }

    public func clearChartAndNode() {
        hostingViewController.rootView.model.clearDetails()
    }

    // called by MasterViewController when the user selects an address
    public func addressSelected(_ address: IPAddress, _ buttons_enabled: Bool) {
        // retrouver le node
        var node: Node? = nil
        if address.getFamily() == AF_INET {
            let v4addr = address as! IPv4Address
            for n in DBMaster.shared.nodes {
                if n.getV4Addresses().contains(v4addr) {
                    node = n
                }
            }
        } else {
            let v6addr = address as! IPv6Address
            for n in DBMaster.shared.nodes {
                if n.getV6Addresses().contains(v6addr) {
                    node = n
                }
            }
        }

        clearChart(new_address: address)
        
        if let node {
            hostingViewController.rootView.model.updateDetails(node, address, buttons_enabled)
        } else {
            print("error: node is null")
        }
    }
    
    public func removeMapButton() {
        DispatchQueue.main.async {
            self.hostingViewController.rootView.model.setButtonMapHiddenState(true)
        }
    }
    
    public func enableButtons(_ state: Bool) {
        // ce dispatch est obligatoire sinon on écrase le modèle par un simple accès à hostingViewController.rootView.model
        // il est async pour éviter une exception
        DispatchQueue.main.async {
            self.hostingViewController.rootView.model.setButtonsEnabled(state)
        }
    }

    public func updateDetailsIfNodeDisplayed(_ node: Node, _ buttons_enabled: Bool) {
        if let v4 = hostingViewController.rootView.model.v4address {
            if node.getV4Addresses().contains(v4) {
                if let node = findNodeFromAddress(v4) {
                    hostingViewController.rootView.model.updateDetails(node, v4, buttons_enabled)
                    clearChart(new_address: v4)
                }
            }
        }
        if let v6 = hostingViewController.rootView.model.v6address {
            if node.getV6Addresses().contains(v6) {
                if let node = findNodeFromAddress(v6) {
                    hostingViewController.rootView.model.updateDetails(node, v6, buttons_enabled)
                    clearChart(new_address: v6)
                }
            }
        }
    }

    public func findNodeFromAddress(_ address: IPAddress) -> Node? {
        if address.getFamily() == AF_INET {
            let v4addr = address as! IPv4Address
            for n in DBMaster.shared.nodes {
                if n.getV4Addresses().contains(v4addr) {
                    return n
                }
            }
        } else {
            let v6addr = address as! IPv6Address
            for n in DBMaster.shared.nodes {
                if n.getV6Addresses().contains(v6addr) {
                    return n
                }
            }
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
