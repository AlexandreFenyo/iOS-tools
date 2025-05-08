//
//  SNMPManager.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 08/05/2025.
//  Copyright © 2025 Alexandre Fenyo. All rights reserved.
//

import iOSToolsMacros

enum SNMPManagerError: Error {
    case notAvailable
}

fileprivate enum SNMPManagerState: Int {
    case available = 0
    case walking
    // Finished state when data pulled by the manager have not been retrieved from it
    case walk_finished
    case pull_finished
}

@MainActor
class SNMPManager {
    static let manager = SNMPManager()
    private var state: SNMPManagerState = .available
    
    init() {
    }

    private func setState(_ state: SNMPManagerState) {
        self.state = state
    }

    private func getState() -> SNMPManagerState {
        if state == .walk_finished && alex_rollingbuf_isempty() == 1 {
            state = .pull_finished
        }
        return state
    }
    
    func walk() throws(SNMPManagerError) {
        if state != .available {
            throw SNMPManagerError.notAvailable
        }
        state = .walking
        alex_rollingbuf_init();

        // Launch a background thread that runs snmpwalk
        Task.detached {
            alex_walk()
            await self.setState(.walk_finished)
        }

        // Launch a background thread that continuously pulls the results from the static length buffer used by alex_walk()
//        return;
        Task.detached {
            while await self.getState() != .pull_finished {
                let len = Int(alex_rollingbuf_poplength())
                if len == -1 {
                    // No value to pull, we wait 0.2 sec for the alex_walk() thread to collect data
                    usleep(useconds_t(200000))
                } else {
                    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: len + 1)
                    let ret = alex_rollingbuf_pop(pointer)
                    if ret == -1 {
                        #fatalError("walk: alex_rollingbuf_pop: \(ret)")
                    } else {
                        let str = String(cString: pointer)
                        // print("RECUP: \(str)")
                    }
                    pointer.deallocate()
                }
            }
            print("FINISHED !")
        }
        
    }
}
