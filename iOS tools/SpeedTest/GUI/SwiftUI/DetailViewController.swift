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
    private var chart_node : SKChartNode?
    private var scene_delegate : MySKSceneDelegate?
    private let ts = TimeSeries()
    
    @IBOutlet weak var view1: SKView!
    @IBOutlet weak var view2: UIView!
    
    private lazy var hostingViewController = makeHostingController()

    private func makeHostingController() -> UIHostingController<DetailSwiftUIView> {
        let hostingController = UIHostingController(rootView: DetailSwiftUIView(view: view))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // sert à rien
//        navigationItem.leftItemsSupplementBackButton = true

        addChild(hostingViewController)
        view2.addSubview(hostingViewController.view)

        //        addChild(hostingViewController)
        //        view.addSubview(hostingViewController.view)

        hostingViewController.didMove(toParent: self)

//        hostingViewController.rootView.pingloop?.start(ts: hostingViewController.rootView.ts)
        
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view2.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view2.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view2.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(equalTo: view2.heightAnchor)
        ])

        let scene = SKScene(size: view1.bounds.size)
        // pour débugguer si taille mal ajustée
        scene.backgroundColor = .brown

        scene_delegate = MySKSceneDelegate()
        scene.delegate = scene_delegate

        view1.presentScene(scene)

        Task {
            await chart_node = SKChartNode(ts: ts, full_size: view1.bounds.size, grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: view1)
            scene.addChild(chart_node!)
            scene_delegate!.nodes.append(chart_node!)
            
            chart_node!.position = CGPoint(x: 0, y: 0)
            chart_node!.registerGestureRecognizers(view: view)

            // view1.showsFPS = true
            // view1.showsQuadCount = true

        }

    }
    
    // called by MasterViewController when the user selects an address
    public func addressSelected(_ address: IPAddress) {
        // retrouver le node
        var node: Node? = nil
        if address.getFamily() == AF_INET {
            let v4addr = address as! IPv4Address
            for n in DBMaster.shared.nodes {
                if n.v4_addresses.contains(v4addr) {
                    node = n
                }
            }
        } else {
            let v6addr = address as! IPv6Address
            for n in DBMaster.shared.nodes {
                if n.v6_addresses.contains(v6addr) {
                    node = n
                }
            }
        }
        
        print("set current_node")
        hostingViewController.rootView.model.setNodeAddress(node!, address)
    }

    /*
    private func refreshUI() {
        print("refresh UI")
        loadViewIfNeeded()
//        detail_label.text = node == nil ? "no selection" : (node!.mcast_dns_names.map { $0.toString() } + node!.dns_names.map { $0.toString() }).first
    }
*/
    
    override func viewDidAppear(_ animated: Bool) {
        if chart_node != nil {
            chart_node!.scene!.view!.isPaused = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        if chart_node != nil {
            chart_node!.scene!.view!.isPaused = true
        }
    }

    /*
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftItemsSupplementBackButton = true

        let scene = SKScene(size: ingress_chart.bounds.size)
        scene.backgroundColor = .brown

        scene_delegate = MySKSceneDelegate()
        scene.delegate = scene_delegate

        ingress_chart.presentScene(scene)

        chart_node = SKChartNode(ts: ts, full_size: ingress_chart.bounds.size, grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: view1)
        scene.addChild(chart_node!)
        scene_delegate!.nodes.append(chart_node!)

        chart_node!.position = CGPoint(x: 0, y: 0)
        chart_node!.registerGestureRecognizers(view: view)

//        ingress_chart.showsFPS = true
//        ingress_chart.showsQuadCount = true

        // enable 1 of the 2 following groups of lines to test

        Timer.scheduledTimer(withTimeInterval: TimeInterval(0.2), repeats: true) {
            _ in
            if DetailViewController.cl == nil { return }
            if DetailViewController.cl!.isFinished {
                DetailViewController.cl!.close();
                DetailViewController.cl = nil
                if self.chart_switch1.isOn {
                    self.chart_switch1.setOn(false, animated: true)
                }
            } else {
                let throughput = DetailViewController.cl!.getThroughput()
                self.ts.add(TimeSeriesElement(date: Date(), value: Float(throughput)))
            }
        }

//        Timer.scheduledTimer(withTimeInterval: TimeInterval(0.2), repeats: true) {
//            _ in
//            if DetailViewController.cl2 == nil { return }
//            if DetailViewController.cl2!.isFinished {
//                DetailViewController.cl2!.close();
//                DetailViewController.cl2 = nil
//                if self.chart_switch1.isOn {
//                    self.chart_switch1.setOn(false, animated: true)
//                }
//            } else {
//                let throughput = DetailViewController.cl2!.getThroughput()
//                self.ts.add(TimeSeriesElement(date: Date(), value: Float(throughput)))
//            }
//        }

    }
*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        print("DetailViewController.prepare(for segue)")
    }
    
    
    
}
