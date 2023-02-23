//
//  LocalHttpClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 22/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// https://developer.apple.com/documentation/foundation/urlsession
// https://www.raywenderlich.com/959-arc-and-memory-management-in-swift

class LocalHttpClient : NSObject, URLSessionDataDelegate {
//    private let address : IPAddress
    private var last_nwrite : Int?
    private var last_date : Date?
    
    public init(url: String) {
//        print("URL:", url)
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let queue = OperationQueue()
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        let task = session.dataTask(with: URL(string: url)!)
        task.resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//        print("web downloaded bytes:", data.count)
    }
    
    
    // Main thread
    public func close() {
    }
    
    // Main thread
    public func stop() {
    }
    
    // Main thread
    public func getNWrite() -> Int {
        return 0
    }
    
    // Main thread
    public func getThroughput() -> Double {
        return 0
    }
}
