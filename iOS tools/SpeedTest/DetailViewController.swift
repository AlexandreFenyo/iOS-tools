//
//  DetailViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 02/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit
import SpriteKit

class DetailViewController: UIViewController {

    private var chart_node : SKChartNode?
    private let ts = TimeSeries()

    @IBOutlet private weak var detail_label: UILabel!

    @IBOutlet private weak var ingress_chart: SKView!

    public var device : Device? {
        didSet {
            refreshUI()
        }
    }

    private func refreshUI() {
        loadViewIfNeeded()
        detail_label.text = device?.name
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftItemsSupplementBackButton = true

        let scene = SKScene(size: CGSize(width: view.frame.size.width / 2, height: view.frame.size.height))
        scene.backgroundColor = .brown
        ingress_chart.presentScene(scene)

        chart_node = SKChartNode(ts: ts, full_size: CGSize(width: 410, height: 300), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 80, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false)
        scene.addChild(chart_node!)
        chart_node!.position = CGPoint(x: 50, y: 100)
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
