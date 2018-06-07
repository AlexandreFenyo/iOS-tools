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
// nc localhost 1919
// dig -p 5353 @mac _ssh._tcp.local. ptr
// dig -p 5353 @224.0.0.251 _chargen._tcp.local. ptr


class MyThread : Thread {
    public var r : RunLoop?
    
    @objc
    func saveR(_ gesture: Int) {
        r = RunLoop.current
        print("saveR:", OperationQueue.current)
    }
    
    public override func main() {
        print("MYTHREAD")
        print("main:", OperationQueue.current)
        r!.run()
        print("FIN MYTHREAD")
    }
}

class MyNetServiceBrowserDelegate : NSObject, NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("netServiceBrowser:", service, moreComing)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didRemoveDomain domainString: String,
                           moreComing: Bool) {
        print("didRemoveDomain")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didFindDomain domainString: String,
                           moreComing: Bool) {
        print("didFindDomain")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didRemove service: NetService,
                           moreComing: Bool) {
        print("didRemove")
    }

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserWillSearch")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didNotSearch errorDict: [String : NSNumber]) {
        print("didNotSearch")
        for err in errorDict {
            print("ERREUR:", err.key, err.value)
        }
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserDidStopSearch")
    }


}

class MyNetServiceDelegate : NSObject, NetServiceDelegate {
    override init() {
        super.init()
        print("init")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("didNotPublish")
    }

    func netServiceDidPublish(_ sender: NetService) {
        print("netServiceDidPublish")
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("didNotResolve")
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("netServiceDidStop")
    }
    
    func netServiceWillPublish(_ sender: NetService) {
        print("netServiceWillPublish")
    }

    func netServiceWillResolve(_ sender: NetService) {
        print("netServiceWillResolve")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolveAddress")
    }
    
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        print("didUpdateTXTRecord")
    }
    
    // https://github.com/shogo4405/HaishinKit.swift/blob/master/Sources/Net/NetSocket.swift
//    var backgroundQueue : DispatchQueue?
//    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
//        print("didAcceptConnectionWith")
//        backgroundQueue = DispatchQueue(label: "net.fenyo.apple.iOS-tools.chargen.read")
//        backgroundQueue!.async {
//            inputStream.open()
//            outputStream.open()
//
//            let content = "0123456789"
//            let data = content.data(using: String.Encoding.utf8, allowLossyConversion: false)!
//            let dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
//            data.copyBytes(to: dataMutablePointer, count: data.count)
//            let dataPointer = UnsafePointer<UInt8>(dataMutablePointer)
//
//            while true {
//                print("loop start")
//
//                while !outputStream.hasSpaceAvailable {
//                    print("not hasSpaceAvailable -> stream status:", outputStream.streamStatus.rawValue)
//                    switch outputStream.streamStatus {
//                    case .atEnd:
//                        print("atEnd")
//                    case .closed:
//                        print("closed")
//                    case .error:
//                        print("error")
//                    case .notOpen:
//                        print("notOpen")
//                    case .open:
//                        print("open")
//                        print(Date())
////                        let ret = outputStream.write(dataPointer, maxLength: data.count)
////                        print("write->", ret)
////                        print(Date())
//                    case .opening:
//                        print("opening")
//                    case .reading:
//                        print("reading")
//                    case .writing:
//                        print("writing")
//                    }
//                    sleep(1)
//                }
//
//                let ret = outputStream.write(dataPointer, maxLength: data.count)
//                print("write -> stream status:", outputStream.streamStatus.rawValue)
//                if ret != data.count { print("write:", ret) }
//                if ret < 0 {
//                    print("write error:", outputStream.streamError!)
//                    break
//                }
//                if ret == 0 {
//                    print("write returned 0:", outputStream.streamError!)
//                }
//            }
//
//            print("quit")
//            dataMutablePointer.deallocate()
//            outputStream.close()
//            inputStream.close()
//        }
    
    var output_stream_delegate : StreamDelegate?
    var r : RunLoop?
    var d : DispatchQueue?
    var t : MyThread?

    // https://github.com/apple/swift/blob/c760f6dfbf0179e9aff90f7bf7375f3af5331318/docs/proposals/Concurrency.rst
    // https://medium.com/flawless-app-stories/basics-of-parallel-programming-with-swift-93fee8425287
    // https://developer.apple.com/library/archive/samplecode/Earthquakes/Listings/Earthquakes_iOS_QuakesViewController_swift.html#//apple_ref/doc/uid/TP40014547-Earthquakes_iOS_QuakesViewController_swift-DontLinkElementID_5
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("didAcceptConnectionWith")
        output_stream_delegate = MyOutputStreamDelegate()
        outputStream.delegate = output_stream_delegate

        outputStream.open()

        t = MyThread()
//        t!.perform(#selector(MyThread.saveR(_:)))
        t!.perform(#selector(MyThread.saveR(_:)), on: t!, with: nil, waitUntilDone: true)
        outputStream.schedule(in: t!.r!, forMode: .commonModes)
        t!.start()

        
//outputStream.schedule(in: <#T##RunLoop#>, forMode: <#T##RunLoopMode#>)

        //        d!.async {
//            print(CFRunLoopGetCurrent())
//        }

//        d!.sync {
//            self.r = .current
////            print(CFRunLoopGetCurrent())
////            print(CFRunLoopGetMain())
//        }
//

//        print(OperationQueue.current)
//        print(OperationQueue.main)

        // outputStream.schedule(in: r!, forMode: .commonModes)

    
    }
}

class MyOutputStreamDelegate : NSObject, StreamDelegate {
    let content : String
    let data : Data
    let dataMutablePointer : UnsafeMutablePointer<UInt8>
    let dataPointer : UnsafePointer<UInt8>

    override init() {
        content = "0123456789"
        data = content.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: dataMutablePointer, count: data.count)
        dataPointer = UnsafePointer<UInt8>(dataMutablePointer)
    }
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            print("openCompleted")
        case .hasBytesAvailable:
            print("hasBytesAvailable")
        case .hasSpaceAvailable:
            print("hasSpaceAvailable")
            let outputStream = aStream as! OutputStream
            let ret = outputStream.write(dataPointer, maxLength: data.count)
print(OperationQueue.current)
            while outputStream.hasSpaceAvailable {
                outputStream.write(dataPointer, maxLength: data.count)
            }
//            print(DispatchQueue.main)
//            print(OperationQueue.current)
//            print(OperationQueue.main)
//            print(CFRunLoopGetCurrent())
//            print(CFRunLoopGetMain())

            //            while true { sleep(1000) }
            print("write->", ret)

        case .errorOccurred:
            print("errorOccurred")
        case .endEncountered:
            print("endEncountered")
        default:
            print("default")
        }
    }
}



class NetTools {
    public static var x = false
    private static var srv : NetService?
    private static var br : NetServiceBrowser?
    public static var dl : MyNetServiceDelegate?
    public static var dl2 : MyNetServiceBrowserDelegate?
    public static var q : DispatchQueue?
    
    // https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW1
    // https://theswiftdev.com/2017/08/29/concurrency-model-in-swift/
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html
    public static func initBonjourService() {
        if !x {
            x = true



            let service = NetService(domain: "local.", type: "_chargen._tcp.", name: "chargen", port: 1919)
            srv = service
            dl = MyNetServiceDelegate()
            service.delegate = dl
            service.publish(options: .listenForConnections)
            print("service published")
        
//            let browser = NetServiceBrowser()
//            br = browser
//            dl2 = MyNetServiceBrowserDelegate()
//            browser.delegate = dl2
////            browser.searchForBrowsableDomains()
//            browser.searchForServices(ofType: "_chargen._tcp.", inDomain: "local.")
//            print("browsing")

//            let q = OperationQueue()
//            var i = 0
//            q.addOperation {
//                while true {
//                    print("operation", i)
//                    i += 1
//                }
//            }

//            // https://developer.apple.com/documentation/corefoundation/1539743-cfreadstreamopen
//            var readStream : Unmanaged<CFReadStream>?
//            var writeStream : Unmanaged<CFWriteStream>?
//            CFStreamCreatePairWithSocketToHost(nil, "localhost" as CFString, 1919, &readStream, &writeStream)
//            CFReadStreamOpen(readStream!.takeRetainedValue())
        }

    }
    
}
