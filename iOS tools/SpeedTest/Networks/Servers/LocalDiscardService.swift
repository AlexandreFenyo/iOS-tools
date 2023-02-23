//
//  NetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// Manage a remote client with two threads, one for each stream
class SpeedTestDiscardClient : SpeedTestClient {
    // Data buffer
    private let bufMutablePointer: UnsafeMutablePointer<UInt8>
    
    // Prepare threads and data buffers to handle a remote client
    public required init(input_stream: InputStream?, output_stream: OutputStream?, from: LocalDelegate) {
        // Prepare data buffer
        bufMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: NetworkDefaults.buffer_size)
        
        // Initialize superclass
        super.init(input_stream: input_stream, output_stream: output_stream, from: from)
    }
    
    // Manage callback I/O events
    public func stream(_ stream: Stream, handle event_code: Stream.Event) {
        switch event_code {
        case .hasBytesAvailable:
            let inputStream = stream as! InputStream
            let ret = inputStream.read(bufMutablePointer, maxLength: NetworkDefaults.buffer_size)
            if ret <= 0 { end(stream) }
            
        case .hasSpaceAvailable:
            // should not happen
            end(stream)

        case .errorOccurred:
            end(stream)
            
        case .endEncountered:
            end(stream)

        default:
            ()
        }
    }
}
