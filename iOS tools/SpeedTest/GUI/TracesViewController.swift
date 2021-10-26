//
//  TracesViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import Foundation

import UIKit
import SwiftUI

class TracesViewController : UIViewController {
    let contentView = UIHostingController(rootView: TracesSwiftUIView())

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView.view)
        contentView.view.frame = view.frame
        addChild(contentView)
        // contentView.didMove(toParent: self)
    }
}
