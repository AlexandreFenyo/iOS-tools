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
// dig -p 5353 @mac _ssh._tcp.local. PTR
// dig -p 5353 @224.0.0.251 _speedtestchargen._tcp.local. PTR
// https://medium.com/flawless-app-stories/memory-leaks-in-swift-bfd5f95f3a74
// Call C from Swift
// DispatchQueue.global(qos: .background).async{ net_test() }

// Connect to a service
//            // https://developer.apple.com/documentation/corefoundation/1539743-cfreadstreamopen
//            var readStream : Unmanaged<CFReadStream>?
//            var writeStream : Unmanaged<CFWriteStream>?
//            CFStreamCreatePairWithSocketToHost(nil, "localhost" as CFString, NetworkDefaults.chargen_port, &readStream, &writeStream)
//            CFReadStreamOpen(readStream!.takeRetainedValue())
// meilleure alternative si on a un NetService : service.getInputStream()

// Default values
struct NetworkDefaults {
    public static let speed_test_chargen_port: Int32 = 1919
    public static let buffer_size = 3000
    public static let local_domain_for_browsing = "local."
    public static let speed_test_chargen_service_type = "_speedtestchargen._tcp."
    public static let speed_test_discard_service_type = "_speedtestdiscard._tcp."
}

// Protocol used to inform with a callback that a child object has done its job
protocol RefClosed {
    func refClosed(_: SpeedTestChargenClient)
}

// Start a run loop to manage a stream
class StreamNetworkThread : Thread {
    private let stream : Stream

    deinit {
        print("StreamNetworkThread deinit")
    }
    
    public init(_ stream: Stream) {
        self.stream = stream
    }

    // Called in the dedicated thread
    override public func main() {
        print("ENTREE")
        stream.open()
        stream.schedule(in: .current, forMode: .commonModes)
        RunLoop.current.run()
        stream.close()
        print("SORTIE")
    }
}

// Manage a remote client with two threads, one for each stream
class SpeedTestChargenClient : NSObject, StreamDelegate {
    private var background_network_thread_in, background_network_thread_out : StreamNetworkThread?
    private let input_stream, output_stream : Stream

    // Needed to inform the the parent that this SpeedTestChargenClient instance can be disposed
    private weak var from : LocalChargenDelegate?

    // Data buffers
    private let dataMutablePointer, bufMutablePointer : UnsafeMutablePointer<UInt8>
    private let dataPointer, bufPointer : UnsafePointer<UInt8>

    deinit {
        print("SpeedTestChargentClient deinit")
    }
    
    public func threadFinished() -> Bool {
        return background_network_thread_in!.isFinished && background_network_thread_out!.isFinished
    }

    // May be called in any thread
    public func exitThreads() {
        // Closing a stream makes it being unscheduled, this will force the run loop to exit
        print("exitThreads")
        // Needed ???
//        background_network_thread_in!.cancel()
//        background_network_thread_out!.cancel()
        input_stream.close()
        output_stream.close()
    }

    // Prepare threads and data buffers to handle a remote client
    public init(input_stream: InputStream, output_stream: OutputStream, from: LocalChargenDelegate) {
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

// Manage callbacks for the speed test chargen service
class LocalChargenDelegate : NSObject, NetServiceDelegate, RefClosed {
    // Strong refs
    private var clients : [SpeedTestChargenClient] = [ ]

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
                    print("TEST")
                    if self.clients[idx].threadFinished() {
                        print("RE/OVE")
                        self.clients.remove(at: idx)
                        nothing_removed = false
                        break
                    }
                }
            } while nothing_removed == false
        }
    }

    // If one client stream is closed, close the other to end communications with this client
    public func refClosed(_ client: SpeedTestChargenClient) {
        client.exitThreads()
    }

    // Wait in the main thread until stream dedicated threads quit, in order to avoid discarding objects (strongly referenced by SpeedTestChargenClient properties in 'clients' array) accessed by those threads. This will freeze the GUI until every clients are disconnected.
    deinit {
        print("deinit NetServiceSpeedTestChargenDelegate")
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
        clients.append(SpeedTestChargenClient(input_stream: inputStream, output_stream: outputStream, from: self))
    }
}

