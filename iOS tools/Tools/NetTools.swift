//
//  NetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// (while sleep .1; do echo salut ; done) | nc 192.168.1.212 1919 > /tmp/bigfile
// simuler one-way: CTRL-D avec nc sur MacOS
// https://github.com/ecnepsnai/BonjourSwift/blob/master/Bonjour.swift
// https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html
// nc localhost 1919
// dig -p 5353 @mac _ssh._tcp.local. ptr
// dig -p 5353 @224.0.0.251 _chargen._tcp.local. ptr
// https://medium.com/flawless-app-stories/memory-leaks-in-swift-bfd5f95f3a74

// Default values
struct NetworkDefaults {
    public static let chargen_port : Int32 = 1919
    public static let buffer_size = 3000
}

// Protocol used to inform with a callback that a child object has done its job
protocol RefClosed {
    func refClosed(_: ChargenClient)
}

// Start a run loop to manage a stream
class StreamNetworkThread : Thread {
    private let stream : Stream
    
    public init(_ stream: Stream) {
        self.stream = stream
    }

    // Called in the dedicated thread
    override public func main() {
        stream.open()
        stream.schedule(in: .current, forMode: .commonModes)
        RunLoop.current.run()
        stream.close()
    }
}

// Manage a remote client with two threads, one for each stream
class ChargenClient : NSObject, StreamDelegate {
    private var background_network_thread_in, background_network_thread_out : StreamNetworkThread?
    private let input_stream, output_stream : Stream

    // Needed to inform the the parent that this ChargenClient instance can be disposed
    private weak var from : NetServiceChargenDelegate?

    // Data buffers
    private let dataMutablePointer, bufMutablePointer : UnsafeMutablePointer<UInt8>
    private let dataPointer, bufPointer : UnsafePointer<UInt8>

    public func threadFinished() -> Bool {
        return background_network_thread_in!.isFinished && background_network_thread_out!.isFinished
    }

    // May be called in any thread
    public func exitThreads() {
        // Closing a stream makes it being unscheduled, this will force the run loop to exit
        input_stream.close()
        output_stream.close()
    }

    // Prepare threads and data buffers to handle a remote client
    public init(input_stream: InputStream, output_stream: OutputStream, from: NetServiceChargenDelegate) {
        self.input_stream = input_stream
        self.output_stream = output_stream

        // Prepare data buffers
        dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: NetworkDefaults.buffer_size)
        dataMutablePointer.initialize(repeating: 65, count: NetworkDefaults.buffer_size)
        dataPointer = UnsafePointer<UInt8>(dataMutablePointer)
        bufMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: NetworkDefaults.buffer_size)
        bufPointer = UnsafePointer<UInt8>(bufMutablePointer)

        // Save callback
        self.from = from

        // Initialize superclass
        super.init()

        // Create input and output threads
        input_stream.delegate = self
        output_stream.delegate = self
        background_network_thread_in = StreamNetworkThread(input_stream)
        background_network_thread_out = StreamNetworkThread(output_stream)
        
        // Beginning at this line, input and output streams must only be accessed from their dedicated threads
        background_network_thread_in!.start()
        background_network_thread_out!.start()
    }

    // Manage callback I/O events
    public func stream(_ stream: Stream, handle event_code: Stream.Event) {
        switch event_code {
        case .hasBytesAvailable:
            let inputStream = stream as! InputStream
            let ret = inputStream.read(bufMutablePointer, maxLength: NetworkDefaults.buffer_size)
            if ret <= 0 { end(stream) }

        case .hasSpaceAvailable:
            let outputStream = stream as! OutputStream
            let ret = outputStream.write(dataPointer, maxLength: NetworkDefaults.buffer_size)
            if ret < 0 { end(stream) }

        case .errorOccurred:
            end(stream)
            
        case .endEncountered:
            end(stream)
            
        default:
            ()
        }
    }
    
    private func end(_ stream: Stream) {
        // Closing the stream makes it being unscheduled, this will force the run loop to exit
        stream.close()
        // Inform the parent object that the stream has just been closed
        DispatchQueue.main.async { self.from?.refClosed(self) }
    }
}

// Manage callbacks for the chargen service
class NetServiceChargenDelegate : NSObject, NetServiceDelegate, RefClosed {
    // Strong refs
    private var clients : [ChargenClient] = [ ]

    // Initialize instance
    public override init() {
        // Initialize superclass
        super.init()

        // Add a background job that sweeps terminated connections
        Timer.scheduledTimer(withTimeInterval: TimeInterval(1), repeats: true) {
            _ in
            var nothing_removed : Bool
            repeat {
                nothing_removed = true
                for idx in self.clients.indices {
                    if self.clients[idx].threadFinished() {
                        self.clients.remove(at: idx)
                        nothing_removed = false
                        break
                    }
                }
            } while nothing_removed == false
        }
    }

    // If one client stream is closed, close the other to end communications with this client
    public func refClosed(_ client: ChargenClient) {
        client.exitThreads()
    }

    // Wait in the main thread until stream dedicated threads quit, in order to avoid discarding objects (strongly referenced by ChargenClient properties in 'clients' array) accessed by those threads. This will freeze the GUI until every clients are disconnected.
    deinit {
        for client in clients { client.exitThreads() }
        while true {
            if clients.count == 0 { break }
            sleep(1)
        }
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
    
    // Manage new connections from clients
    public func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        clients.append(ChargenClient(input_stream: inputStream, output_stream: outputStream, from: self))
    }
}


class NetServiceChargenBrowserDelegate : NSObject, NetServiceBrowserDelegate {
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
    private static var br : NetServiceBrowser?
    public static var dl2 : NetServiceChargenBrowserDelegate?
    
    public static var x = false
    
    public static func initBonjourService() {
        if !x {
            x = true
            
            // Create chargen service
            let net_service_chargen = NetService(domain: "local.", type: "_chargen._tcp.", name: "chargen", port: NetworkDefaults.chargen_port)
            net_service_chargen.delegate = NetServiceChargenDelegate()
            
            // Start listening for chargen clients
            net_service_chargen.publish(options: .listenForConnections)

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
