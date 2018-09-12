//
//  NavigationBar.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 12/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

class NavigationBar : UINavigationBar {
    
}

class NavigationController : UINavigationController {
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        print("salut")
         super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        print("salut2")
//        super.init(coder: aDecoder)
        super.init(navigationBarClass: nil, toolbarClass: nil)
    }

}
