//
//  DetailViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 02/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit
import SpriteKit

class MySKSceneDelegate : NSObject, SKSceneDelegate {
    public var nodes : [SKChartNode] = []

    public func update(_ currentTime: TimeInterval, for scene: SKScene) {
        for n in nodes { n.updateWidth() }
    }
}

class DetailViewController: UIViewController {
    private var chart_node : SKChartNode?
    private var scene_delegate : MySKSceneDelegate?
    private let ts = TimeSeries()

    private static var cl: LocalChargenClient?
    private static var cl2: LocalDiscardClient?
    private static var cl3: LocalPingClient?
    private static var cl4: LocalFloodClient?

    @IBOutlet weak var view1: UIView!

    @IBOutlet private weak var detail_label: UILabel!

    @IBOutlet private weak var ingress_chart: SKView!

    @IBOutlet weak var chart_switch1: UISwitch!
    
    // Node selected by the user
    public var node : Node? {
        didSet {
            if oldValue !== node {
                refreshUI()
            }
        }
    }

    // Address selected by the user
    public var address : IPAddress? {
        didSet {
            if oldValue != address {
                refreshUI()
            }
        }
    }

    private func refreshUI() {
        print("refresh UI")
        loadViewIfNeeded()
        detail_label.text = node == nil ? "no selection" : (node!.mcast_dns_names.map { $0.toString() } + node!.dns_names.map { $0.toString() }).first
    }

    override func viewDidAppear(_ animated: Bool) {
        chart_node!.scene!.view!.isPaused = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        chart_node!.scene!.view!.isPaused = true
    }

    @objc
    private func switchChanged(_ sender: Any) {
        if sender as? UISwitch == chart_switch1, chart_switch1.isOn == true {
            if DetailViewController.cl != nil {
                print("switchChanged warning: already running")
                chart_switch1.setOn(false, animated: true)
                return
            }

            // démarrer les stats
            print("address:", address!)
// à remettre
//            DetailViewController.cl = LocalChargenClient(address: address!)
//            DetailViewController.cl!.start()
            
// à remettre
// test ping
//            DetailViewController.cl3 = LocalPingClient(address: address!)
//            DetailViewController.cl3!.start()

            // à remettre
            // test flood
            DetailViewController.cl4 = LocalFloodClient(address: address!)
            DetailViewController.cl4!.start()

        }

        if sender as? UISwitch == chart_switch1, chart_switch1.isOn == false {
            if DetailViewController.cl == nil {
                print("switchChanged warning: was not running")
                return
            }

            print("disconnect from:", address!)
            DetailViewController.cl!.stop()
        }
    }

    @objc
    private func switch2Changed(_ sender: Any) {
        if sender as? UISwitch == chart_switch1, chart_switch1.isOn == true {
            if DetailViewController.cl2 != nil {
                print("switchChanged warning: already running")
                chart_switch1.setOn(false, animated: true)
                return
            }
            
            // démarrer les stats
            print("address:", address!)
            DetailViewController.cl2 = LocalDiscardClient(address: address!)
            DetailViewController.cl2!.start()
        }
        
        if sender as? UISwitch == chart_switch1, chart_switch1.isOn == false {
            if DetailViewController.cl2 == nil {
                print("switchChanged warning: was not running")
                return
            }
            
            print("disconnect from:", address!)
            DetailViewController.cl2!.stop()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftItemsSupplementBackButton = true

        // enable 1 of the 2 following lines to test
        chart_switch1!.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        // chart_switch1!.addTarget(self, action: #selector(switch2Changed(_:)), for: .valueChanged)

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
