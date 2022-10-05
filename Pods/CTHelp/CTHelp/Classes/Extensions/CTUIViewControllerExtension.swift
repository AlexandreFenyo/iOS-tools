//
//  UIViewControllerExtension.swift
//  
//
//  Created by Stewart Lynch on 1/16/19.
//  Copyright © 2019 Stewart Lynch. All rights reserved.
//

import UIKit

public extension UIViewController {
    static func loadTransparentModal(fromStoryboardNamed name: String) -> UIViewController {
		//let bundle = Bundle(for: type(of: CTHelpViewController.self))
		let podBundle = Bundle(for: CTHelpViewController.self)
		let bundleURL = podBundle.url(forResource: "CTHelp", withExtension: "bundle")
		let bundle = Bundle(url: bundleURL!)
        let storyboard =  UIStoryboard(name: name, bundle: bundle)
        let newVC = storyboard.instantiateViewController(withIdentifier: String(describing: self))
        newVC.providesPresentationContextTransitionStyle = true
        newVC.definesPresentationContext = true
        newVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        newVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        return newVC
    }
    
}
