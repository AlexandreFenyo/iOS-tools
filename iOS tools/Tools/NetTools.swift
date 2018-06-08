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

class BackgroundNetworkThread : Thread {
    public var run_loop : RunLoop?

    override public func main() {
        // Create the run loop
        run_loop = RunLoop.current

        // Prevent the run loop to exit when there is no registered input source
        run_loop!.add(Timer(timeInterval: TimeInterval(3600), repeats: true, block: { _ in }), forMode: RunLoopMode.commonModes)

        // Handle events in the background thread
        run_loop!.run()
    }
}

class MyNetServiceBrowserDelegate : NSObject, NetServiceBrowserDelegate {
    deinit {
        print("MyNetServiceBrowserDelegate.deinit")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("netServiceBrowser:", service, moreComing)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveremoDomain domainString: String, moreComing: Bool) {
        print("didRemoveDomain")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("didFindDomain")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("didRemove")
    }

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserWillSearch")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("didNotSearch")
        for err in errorDict { print("ERREUR:", err.key, err.value) }
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserDidStopSearch")
    }
}

class ChargenClient {
    public let input_stream : InputStream
    public let output_stream : OutputStream
    private let stream_delegate : StreamDelegate
    
    public init(input_stream: InputStream, output_stream: OutputStream, stream_delegate: StreamDelegate) {
        self.input_stream = input_stream
        self.output_stream = output_stream
        self.stream_delegate = stream_delegate
    }
}

class NetServiceChargenDelegate : NSObject, NetServiceDelegate {
    private var clients : [ChargenClient] = []
    
    deinit {
        print("NetServiceChargenDelegate.deinit")
    }

    public func removeClient(stream: Stream) {
        for i in clients.indices {
            if (stream == clients[i].input_stream || stream == clients[i].output_stream) {
                clients.remove(at: i)
                print("REMOVE")
                break
            }
        }
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

    // Manage new connections
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        let stream_delegate = StreamChargenDelegate()
        clients.append(ChargenClient(input_stream: inputStream, output_stream: outputStream, stream_delegate: stream_delegate))

        // Handle stream callbacks on a background thread
        for s in [inputStream, outputStream] {
            s.delegate = stream_delegate
            s.open()
            s.schedule(in: NetTools.background_network_thread!.run_loop!, forMode: .commonModes)
        }
    }
}

class StreamChargenDelegate : NSObject, StreamDelegate {
    private let content = "0123456789"
    private let data : Data
    private let dataMutablePointer : UnsafeMutablePointer<UInt8>
    private let dataPointer : UnsafePointer<UInt8>

    private let bufMutablePointer : UnsafeMutablePointer<UInt8>
    private let bufPointer : UnsafePointer<UInt8>

    deinit {
        print("StreamChargenDelegate.deinit")
    }

    override init() {
        data = content.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: dataMutablePointer, count: data.count)
        dataPointer = UnsafePointer<UInt8>(dataMutablePointer)

        bufMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 10)
        bufPointer = UnsafePointer<UInt8>(bufMutablePointer)
    }
    
    public func stream(_ stream: Stream, handle event_code: Stream.Event) {
        switch event_code {
        case .openCompleted:
            print("openCompleted")

        case .hasBytesAvailable:
//            print("hasBytesAvailable")
            let inputStream = stream as! InputStream
            let ret = inputStream.read(bufMutablePointer, maxLength: 10)
//            print("read=->", ret)

        case .hasSpaceAvailable:
//            print("hasSpaceAvailable")
            let outputStream = stream as! OutputStream
            let ret = outputStream.write(dataPointer, maxLength: data.count)
  //          print("write->", ret)

        case .errorOccurred:
            print("errorOccurred")
            end(stream)
            
        case .endEncountered:
            print("endEncountered")

        default:
            print("default")
        }
    }
    
    private func end(_ stream: Stream) {
        DispatchQueue.main.sync {
            // Implicitely remove the stream from the run loop
//            stream.close()
            
            // May be useless since the delegate property is declared unowned(unsafe)
            stream.delegate = nil
            
//            NetTools.net_service_chargen_delegate!.removeClient(stream: stream)

         stream.close()

        }
    }
    
}

class NetTools {
    public static var background_network_thread : BackgroundNetworkThread?

    private static var net_service_chargen : NetService?
    public static var net_service_chargen_delegate : NetServiceChargenDelegate?

    private static var br : NetServiceBrowser?
    public static var dl2 : MyNetServiceBrowserDelegate?

    public static var x = false

    public static func initBonjourService() {
        if !x {
            x = true

            // Create and start background thread for networking operations
            background_network_thread = BackgroundNetworkThread()
            background_network_thread!.start()

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
