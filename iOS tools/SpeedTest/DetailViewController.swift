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

    @IBOutlet weak var view1: UIView!

    @IBOutlet private weak var detail_label: UILabel!

    @IBOutlet private weak var ingress_chart: SKView!

    @IBOutlet weak var chart_switch1: UISwitch!

    public var device : Device? {
        didSet {
            refreshUI()
        }
    }

    private func refreshUI() {
        loadViewIfNeeded()
        detail_label.text = device?.name
    }

    override func viewDidAppear(_ animated: Bool) {
        chart_node!.scene!.view!.isPaused = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        chart_node!.scene!.view!.isPaused = true
    }

    @objc
    private func switchChanged(_ sender: Any) {
        if sender as? UISwitch == chart_switch1, chart_switch1.isOn {
            // démarrer les stats
            let cl = LocalChargenClient()

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftItemsSupplementBackButton = true

        chart_switch1!.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)

        let scene = SKScene(size: ingress_chart.bounds.size)
        scene.backgroundColor = .brown

        scene_delegate = MySKSceneDelegate()
        scene.delegate = scene_delegate

        ingress_chart.presentScene(scene)

        chart_node = SKChartNode(ts: ts, full_size: ingress_chart.bounds.size, grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 80, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: view1)
        scene.addChild(chart_node!)
        scene_delegate!.nodes.append(chart_node!)

        chart_node!.position = CGPoint(x: 0, y: 0)
        chart_node!.registerGestureRecognizers(view: view)

//        ingress_chart.showsFPS = true
//        ingress_chart.showsQuadCount = true
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
