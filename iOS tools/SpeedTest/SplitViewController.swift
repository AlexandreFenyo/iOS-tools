//
//  ViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 02/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }
    
    override func viewWillLayoutSubviews() {
//        preferredPrimaryColumnWidthFraction = 0.3
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // on iPhone, show the primary view controller's view by default
    // https://stackoverflow.com/questions/25875618/uisplitviewcontroller-in-portrait-on-iphone-shows-detail-vc-instead-of-master
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

            print("SplitViewController.prepare(for segue)")
    }

}
