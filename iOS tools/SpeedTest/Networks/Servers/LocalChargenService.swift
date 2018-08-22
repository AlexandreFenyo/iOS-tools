//
//  NetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// Manage a remote client with two threads, one for each stream
class SpeedTestChargenClient : SpeedTestClient {
    // Data buffers
    private let dataMutablePointer, bufMutablePointer : UnsafeMutablePointer<UInt8>
    private let dataPointer : UnsafePointer<UInt8>

    // Prepare threads and data buffers to handle a remote client
    public required init(input_stream: InputStream?, output_stream: OutputStream?, from: LocalDelegate) {
        // Prepare data buffers
        dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: NetworkDefaults.buffer_size)
        dataMutablePointer.initialize(repeating: 65, count: NetworkDefaults.buffer_size)
        dataPointer = UnsafePointer<UInt8>(dataMutablePointer)
        bufMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: NetworkDefaults.buffer_size)

        // Initialize superclass
        super.init(input_stream: input_stream, output_stream: output_stream, from: from)
    }

    // Callback from the system since it is a StreamDelegate
    // The delegate receives this message only if theStream is scheduled on a run loop
    // Manage callback I/O events
    public func stream(_ stream: Stream, handle event_code: Stream.Event) {
        switch event_code {
        case .hasBytesAvailable:
            let inputStream = stream as! InputStream
            let ret = inputStream.read(bufMutablePointer, maxLength: NetworkDefaults.buffer_size)
            if ret <= 0 {
                print("inputStream end")
                end(stream)
            }

        case .hasSpaceAvailable:
            let outputStream = stream as! OutputStream
            let ret = outputStream.write(dataPointer, maxLength: NetworkDefaults.buffer_size)
            if ret < 0 {
                print("outputStream end")
                end(stream)
            }

        case .errorOccurred:
            end(stream)
            
        case .endEncountered:
            end(stream)
            
        default:
            ()
        }
    }
}
