//
//  GenericTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// "alt" means "alternative"

// read plist: defaults read /Users/fenyo/Library/Developer/Xcode/DerivedData/iOS_tools-epwocfsynihtagcdtrgfzhdwlvrf/Build/Products/Debug-iphoneos/iOS\ tools.app/Info.plist

import Foundation

final class GenericTools : AutoTrace {
    static let must_log = (NSDictionary(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "plist")!)!.object(forKey: "log") ?? false) as! Bool

    // Basic debugging
    // Can be declared these ways:Ò
    // static func here() -> () {
    // static func here() -> Void {
    // static func here() {
    static func here() {
        if !must_log { return }
        print("here");
    }

    // Basic debugging
    // ex.: here("here")
    //      here("here", self)
    static func here(_ s: String, _ o: Any? = nil) {
        if !must_log { return }
        if o == nil {
            print("here:", s);
        } else {
            // print(o.debugDescription) prints the instance as an Optional
            // print(o!.debugDescription) does not compile ("Value of type 'Any' has no member 'debugDescription'")
            print("here: ", o!, ":", s, separator: String() /* alt: separator: "" */)
        }
    }
    
    // The previous function can also we written with o as an implicitely unwrapped Optional wrapping an instance of Any? (Any?!), like this:
    // static func here(_ s: String, _ o: Any?! = nil) {
    // ...
    // print("here:", s, "instance:", o)
    // ...

    // placeholder for tests
    static func test() {
    }

}

protocol AutoTrace {
}

extension AutoTrace {
    
}
