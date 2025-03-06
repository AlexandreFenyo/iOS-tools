//
//  MyTabBarController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 06/11/2024.
//  Based on https://stackoverflow.com/questions/78631030/how-to-disable-the-new-uitabbarcontroller-view-style-in-ipados-18

import Foundation
import UIKit

class MyTabBarController: UITabBarController {

    /// Active for iPads running iOS 18+ where the traditional tab bar has been removed by Apple
    lazy var alternateTabBarActive: Bool = {
    #if compiler(>=6.0) // Compiler flag for Xcode >= 16
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            self.isTabBarHidden = true
            return true
        }
    #endif
        return false
    }()
    
    var tabBarHeightConstraint: NSLayoutConstraint?
    
    lazy var alternateTabBar: UITabBar = {
        UITabBar()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.alternateTabBarActive {
            self.tabBar.isHidden = true
            
            self.alternateTabBar.items = self.tabBar.items
            self.alternateTabBar.selectedItem = self.tabBar.selectedItem
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                // Add Custom Tabbar
                let tabbar = self.alternateTabBar
                self.view.addSubview(tabbar)
                
                // Add layout constraints
                tabbar.translatesAutoresizingMaskIntoConstraints = false
                let bottom = tabbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                let leading = tabbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
                let trailing = tabbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                let height = NSLayoutConstraint(item: self.alternateTabBar, attribute: .height, relatedBy: .equal,
                                                toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1)
                self.tabBarHeightConstraint = height
                self.view.addConstraints([bottom, leading, trailing, height])
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.alternateTabBarActive {
            self.alternateTabBar.items = self.tabBar.items
            self.alternateTabBar.selectedItem = self.tabBar.selectedItem
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.alternateTabBarActive {
            // Adjust height constraint
            let height = self.alternateTabBar.intrinsicContentSize.height
            self.tabBarHeightConstraint?.constant = height
            
            // Set insets for child view controllers
            let bottomInset = self.alternateTabBar.frame.size.height-self.view.safeAreaInsets.bottom
            self.viewControllers?.forEach { $0.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0) }
        }
    }

}
