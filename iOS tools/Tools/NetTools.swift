//
//  NetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// bug actuel :
// nc localhost 1919  < /dev/urandom

// https://github.com/ecnepsnai/BonjourSwift/blob/master/Bonjour.swift
// https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html
// nc localhost 1919
// dig -p 5353 @mac _ssh._tcp.local. ptr
// dig -p 5353 @224.0.0.251 _chargen._tcp.local. ptr
// https://medium.com/flawless-app-stories/memory-leaks-in-swift-bfd5f95f3a74

// Default values
struct NetworkDefaults {
    static let chargen_port : Int32 = 1919
}

// Protocol used to inform with a callback that a child object has done its job
protocol RefClosed {
    func refClosed(_: ChargenClient)
}

// Handle thread and run loop dedicated for a single input or output stream
class StreamNetworkThread : Thread {
    private let stream : Stream
    
    public init(_ stream: Stream) {
        self.stream = stream
    }

    // Called in the dedicated thread
    override public func main() {
        stream.open()
        stream.schedule(in: .current, forMode: .commonModes)

        print("START LOOP")
        RunLoop.current.run(iuntil)
        print("QUIT LOOP")

        stream.close()
        // Stream delegate can no more be called for events on this stream
    }
}

class ChargenClient : NSObject, StreamDelegate {
    public var background_network_thread_in : StreamNetworkThread?
    public var background_network_thread_out : StreamNetworkThread?

    // Needed to inform the the parent that this ChargenClient instance can be disposed
    private weak var from : NetServiceChargenDelegate?
    
    private let content = "0123456789"
    private let data : Data
    private let dataMutablePointer : UnsafeMutablePointer<UInt8>
    private let dataPointer : UnsafePointer<UInt8>
    private let bufMutablePointer : UnsafeMutablePointer<UInt8>
    private let bufPointer : UnsafePointer<UInt8>

    public func cancelThreads() {
        background_network_thread_in!.cancel()
        background_network_thread_out!.cancel()
    }
    
    public init(input_stream: InputStream, output_stream: OutputStream, from: NetServiceChargenDelegate) {
        data = content.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: dataMutablePointer, count: data.count)
        dataPointer = UnsafePointer<UInt8>(dataMutablePointer)
        bufMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 10)
        bufPointer = UnsafePointer<UInt8>(bufMutablePointer)

        self.from = from

        super.init()
        
        input_stream.delegate = self
        output_stream.delegate = self
        background_network_thread_in = StreamNetworkThread(input_stream)
        background_network_thread_out = StreamNetworkThread(output_stream)
        
        // Until now, input and output streams must only be accessed from their dedicated threads
        background_network_thread_in!.start()
        background_network_thread_out!.start()
    }

    deinit {
        print("ChargenClient.deinit")
    }
    
    public func stream(_ stream: Stream, handle event_code: Stream.Event) {
        switch event_code {
        case .openCompleted:
            print("openCompleted")
            
        case .hasBytesAvailable:
            //            print("hasBytesAvailable")
            let inputStream = stream as! InputStream
            let ret = inputStream.read(bufMutablePointer, maxLength: 10)
            if ret <= 0 { end(stream) }
            //            print("read=->", ret)
            
        case .hasSpaceAvailable:
            //            print("hasSpaceAvailable")
            let outputStream = stream as! OutputStream
            let ret = outputStream.write(dataPointer, maxLength: data.count)
            if ret < 0 { end(stream) }
            //          print("write->", ret)
            
        case .errorOccurred:
            print("errorOccurred")
            end(stream)
            
        case .endEncountered:
            print("endEncountered")
            end(stream)
            
        default:
            print("default")
        }
    }
    
    private func end(_ stream: Stream) {
        print("END->CLOSE")
        // Unschedule the stream, this will make the run loop to exit
        stream.close()
        DispatchQueue.main.sync { self.from?.refClosed(self) }
    }
}

class NetServiceChargenDelegate : NSObject, NetServiceDelegate, RefClosed {
    private var clients : [ChargenClient] = [ ]

    public func refClosed(_ client: ChargenClient) {
        print("REMOVE")
        client.cancelThreads()
    }
    
    deinit {
        print("NetServiceChargenDelegate.deinit")
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("didNotPublish")
    }
    
    public func netServiceDidPublish(_ sender: NetService) {
        print("netServiceDidPublish")
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("didNotResolve")
    }
    
    public func netServiceDidStop(_ sender: NetService) {
        print("netServiceDidStop")
    }
    
    public func netServiceWillPublish(_ sender: NetService) {
        print("netServiceWillPublish")
    }
    
    public func netServiceWillResolve(_ sender: NetService) {
        print("netServiceWillResolve")
    }
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolveAddress")
    }
    
    public func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        print("didUpdateTXTRecord")
    }
    
    // Manage new connections
    public func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("ACCEPT")
        
        // Sweep previous connections
        var empty : Bool
        repeat {
            empty = true
            for idx in clients.indices {
                if clients[idx].background_network_thread_in!.isFinished && clients[idx].background_network_thread_out!.isFinished {
                    clients.remove(at: idx)
                    empty = false
                    break
                }
            }
        } while empty == false

        clients.append(ChargenClient(input_stream: inputStream, output_stream: outputStream, from: self))
    }
}


class MyNetServiceBrowserDelegate : NSObject, NetServiceBrowserDelegate {
    deinit {
        print("MyNetServiceBrowserDelegate.deinit")
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("netServiceBrowser:", service, moreComing)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("didRemoveDomain")
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("didFindDomain")
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("didRemove")
    }
    
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserWillSearch")
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("didNotSearch")
        for err in errorDict { print("ERREUR:", err.key, err.value) }
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserDidStopSearch")
    }
}
class NetTools {
    private static var net_service_chargen : NetService?
    public static var net_service_chargen_delegate : NetServiceChargenDelegate?
    
    private static var br : NetServiceBrowser?
    public static var dl2 : MyNetServiceBrowserDelegate?
    
    public static var x = false
    
    public static func initBonjourService() {
        if !x {
            x = true
            
            // Create chargen service
            net_service_chargen = NetService(domain: "local.", type: "_chargen._tcp.", name: "chargen", port: NetworkDefaults.chargen_port)
            
            // Add a strong ref to the delegate since NetService.delegate is declared unowned(unsafe)
            net_service_chargen_delegate = NetServiceChargenDelegate()
            net_service_chargen!.delegate = net_service_chargen_delegate
            
            // Start listening for chargen clients
            net_service_chargen!.publish(options: .listenForConnections)
            
            
            
            //            let browser = NetServiceBrowser()
            //            br = browser
            //            dl2 = MyNetServiceBrowserDelegate()
            //            browser.delegate = dl2
            ////            browser.searchForBrowsableDomains()
            //            browser.searchForServices(ofType: "_chargen._tcp.", inDomain: "local.")
            //            print("browsing")
            
            //            // https://developer.apple.com/documentation/corefoundation/1539743-cfreadstreamopen
            //            var readStream : Unmanaged<CFReadStream>?
            //            var writeStream : Unmanaged<CFWriteStream>?
            //            CFStreamCreatePairWithSocketToHost(nil, "localhost" as CFString, NetworkDefaults.chargen_port, &readStream, &writeStream)
            //            CFReadStreamOpen(readStream!.takeRetainedValue())
        }
        
    }
    
}
