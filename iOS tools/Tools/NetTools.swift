//
//  NetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class MyNetServiceBrowserDelegate : NSObject, NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser,didFind service: NetService, moreComing: Bool) {
        print("netServiceBrowser")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didRemoveDomain domainString: String,
                           moreComing: Bool) {
        print("netServiceBrowser")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didFindDomain domainString: String,
                           moreComing: Bool) {
        print("netServiceBrowser")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didRemove service: NetService,
                           moreComing: Bool) {
        print("netServiceBrowser")
    }

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowser")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didNotSearch errorDict: [String : NSNumber]) {
        print("netServiceBrowser")
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowser")
    }


}

class NetTools {
    public static func initBonjourService() {

        let service = NetService(domain: "local.", type: "_chargen._tcp.", name: "chargen", port: 19)
        service.publish()
        print("service published")
        
        let browser = NetServiceBrowser()
        browser.delegate = MyNetServiceBrowserDelegate()
        browser.searchForServices(ofType: "_chargen._tcp.", inDomain: "local.")
        print("browsing")

    }
    
}
