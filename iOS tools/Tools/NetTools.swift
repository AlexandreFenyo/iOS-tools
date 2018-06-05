//
//  NetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/NetServices/Introduction.html
// https://github.com/ecnepsnai/BonjourSwift/blob/master/Bonjour.swift
// https://github.com/Bouke/NetService
// dig -p 5353 @mac _ssh._tcp.local. ptr
// dig -p 5353 @224.0.0.251 _chargen._tcp.local. ptr

class MyNetServiceBrowserDelegate : NSObject, NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
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

class MyNetServiceDelegate : NSObject, NetServiceDelegate {
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("ERREUR")
    }

    func netServiceDidPublish(_ sender: NetService) {
        print("DIDPUB")
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("did not resolv")
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("did stop")
    }
    
    func netServiceWillPublish(_ sender: NetService) {
        print("will")
    }

    func netServiceWillResolve(_ sender: NetService) {
        print("will res")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("xxx")
    }
    
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        print("xxx")
    }
    
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("accepted")
    }
}


class NetTools {
    public static var x
        = false
    
    public static func initBonjourService() {
        if !x {
            x = true
            let service = NetService(domain: "local.", type: "_chargen._tcp.", name: "chargen", port: 1919)
            service.delegate = MyNetServiceDelegate()
            service.publish(options: .listenForConnections)
//            service.schedule(in: .main, forMode: .defaultRunLoopMode)
            print("service published")
        
            let browser = NetServiceBrowser()
            browser.delegate = MyNetServiceBrowserDelegate()
            browser.searchForBrowsableDomains()
//            browser.searchForServices(ofType: "_chargen._tcp.", inDomain: "local.")
            browser.searchForServices(ofType: "_ssh._tcp.", inDomain: "local.")
            print("browsing")

//            let q = OperationQueue()
//            var i = 0
//            q.addOperation {
//                while true {
//                    print("operation", i)
//                    i += 1
//                }
//            }

            // https://developer.apple.com/documentation/corefoundation/1539743-cfreadstreamopen
            var readStream : Unmanaged<CFReadStream>?
            var writeStream : Unmanaged<CFWriteStream>?
            CFStreamCreatePairWithSocketToHost(nil, "localhost" as CFString, 1919, &readStream, &writeStream)
            CFReadStreamOpen(readStream!.takeRetainedValue())
        }

    }
    
}
