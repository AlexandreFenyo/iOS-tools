//
//  NetworkServiceListener.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 25/01/2023.
//  Copyright © 2023 Alexandre Fenyo. All rights reserved.
//

// Bugs in iOS seem to avoid such a way to have a listening service on a TCP port

/*
import Foundation
import Network

 class NetworkServiceListener {
 private let domain: String
 private let type: String
 private let name: String
 private let port: NWEndpoint.Port
 
 private let params: NWParameters
 private var listener: NWListener?
 
 private var connections = [NWConnection]()
 
 init(domain: String, type: String, name: String, port: UInt16) {
 self.domain = domain
 self.type = type
 self.name = name
 let tcp_options = NWProtocolTCP.Options()
 params = NWParameters(tls: nil, tcp: tcp_options)
 params.allowLocalEndpointReuse = true
 params.includePeerToPeer = true
 //        self.port = NWEndpoint.Port(rawValue: port)!
 self.port = NWEndpoint.Port(rawValue: 9)!
 }
 
 // Called by main thread
 private func stateUpdateHandler(_ newState: NWListener.State) -> Void {
 //        print("XXXXX: \(#function) ")
 dump(newState)
 
 switch newState {
 case .setup:
 //            print(".setup")
 break
 
 //        case .waiting(let error):
 case .waiting(_):
 break
 //            print(".waiting")
 //            print("XXXXX: waiting " + error.debugDescription)
 
 case .ready:
 //            print(".ready")
 break
 
 case .cancelled:
 //            print(".cancelled")
 stop()
 start()
 break
 
 case .failed(let error):
 print("\(#function): failed: " + error.debugDescription)
 listener!.cancel()
 
 default:
 break
 }
 
 }
 
 /*
  private func connectionStateUpdateHandler(_ state: NWConnection.State) -> Void {
  //        print(#function)
  switch state {
  //        case .waiting(let error):
  case .waiting(_):
  //            print("cx.waiting")
  break
  case .setup:
  //            print("cx.setup")
  break
  case .cancelled:
  //            print("cx.cancelled")
  break
  //        case .failed(let error):
  case .failed(_):
  //            print("cx.failed")
  break
  case .preparing:
  //            print("cx.preparing")
  break
  case .ready:
  //            print("cx.ready")
  break
  default:
  break
  }
  }
  */
 
 // Called by main thread
 private func newConnectionHandler(_ connection: NWConnection) -> Void {
 print("new connection")
 connections.append(connection)
 // connection.stateUpdateHandler = connectionStateUpdateHandler
 connection.stateUpdateHandler = { [weak connection] state in
 switch state {
 //            case .waiting(let error):
 case .waiting(_):
 //                print("cx.waiting")
 break
 case .setup:
 //                print("cx.setup")
 break
 case .cancelled:
 //                print("cx.cancelled")
 break
 //            case .failed(let error):
 case .failed(_):
 //                print("cx.failed")
 break
 case .preparing:
 //                print("cx.preparing")
 break
 case .ready:
 //                print("cx.ready")
 connection!.cancel()
 break
 default:
 break
 }
 }
 
 // Connection events are delivered to the main queue
 connection.start(queue: .main)
 //        connection.cancel()
 //        connection.forceCancel()
 }
 
 func stop() {
 for conn in connections {
 //            print("CANCELLING")
 //            conn.cancel()
 conn.stateUpdateHandler = nil
 //            conn.forceCancel()
 }
 connections.removeAll()
 listener!.stateUpdateHandler = nil
 listener!.newConnectionHandler = nil
 listener = nil
 }
 
 func start() {
 let tcp_options = NWProtocolTCP.Options()
 let params = NWParameters(tls: nil, tcp: tcp_options)
 params.allowLocalEndpointReuse = true
 params.includePeerToPeer = true
 
 
 listener = try! NWListener(using: params, on: self.port)
 
 //        listener.service = NWListener.Service(name: "speedtestchargen", type: "_service._tcp")
 listener!.service = NWListener.Service(name: name, type: type)
 
 // Connection events are delivered to newConnectionHandler(), so to the main queue (see newConnectionHandler())
 listener!.newConnectionHandler = newConnectionHandler
 
 // Listener state events are delivered to stateUpdateHandler(), so to the main queue (see below)
 listener!.stateUpdateHandler = stateUpdateHandler
 
 // Listener events are delivered to the main queue
 listener!.start(queue: .main)
 }
 
 }
 */
