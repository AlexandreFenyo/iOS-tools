//
//  GenericTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 16/04/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// "alt" means "alternative"

import Foundation

final class GenericTools : AutoTrace {

    // Basic debugging
    // Can be declared these ways:
    // static func here() -> () {
    // static func here() -> Void {
    // static func here() {
    static func here() {
        print("here");
    }

    // Basic debugging
    // ex.: here("here")
    //      here("here", self)
    static func here(_ s: String, _ o: Any? = nil) {
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

}

protocol AutoTrace {
}

extension AutoTrace {
}
