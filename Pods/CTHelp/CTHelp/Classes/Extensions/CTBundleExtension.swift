//
//  BundleExtension.swift
//  
//
//  Created by Stewart Lynch on 1/16/19.
//  Copyright © 2019 Stewart Lynch. All rights reserved.
//

import Foundation
public extension Bundle {
    var displayName: String {
        let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return name ?? object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
    }
    
    var appVersion:String {
        let version = object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return version ?? object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }
}
