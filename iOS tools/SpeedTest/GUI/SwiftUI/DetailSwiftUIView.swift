//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

var delta: CGFloat?

actor PingLoop {
    private var s: Int32?
    
    init() {
        s = socket(PF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
        if s == nil || s! < 0 {
            GenericTools.perror("socket")
            fatalError("chart: socket")
        }
    }
    
    public func start(ts: TimeSeries, address: IPAddress) async throws {
        stop()
        
        if  address.getFamily() == AF_INET {
            print("SALUT")
            
            //            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            print("PING LOOP for \(address)")
            ts.add(TimeSeriesElement(date: Date(), value: 50))
            
            //                DispatchQueue.global(qos: .userInitiated).async {
            repeat {
                print("envoi ICMP")
                
                var hdr = icmp()
                hdr.icmp_type = UInt8(ICMP_ECHO)
                hdr.icmp_code = 0
                hdr.icmp_hun.ih_idseq.icd_seq = _htons(13)
                let capacity = MemoryLayout<icmp>.size / MemoryLayout<ushort>.size
                hdr.icmp_cksum = withUnsafePointer(to: &hdr) {
                    $0.withMemoryRebound(to: u_short.self, capacity: capacity) {
                        var sum : u_short = 0
                        for idx in 0..<capacity { sum = sum &+ $0[idx] }
                        sum ^= u_short.max
                        return sum
                    }
                }
                
                let ret = withUnsafePointer(to: &hdr) { (bytes) -> Int in
                    address.toSockAddress()!.getData().withUnsafeBytes {
                        sendto(s!, bytes, MemoryLayout<icmp>.size, 0, $0.bindMemory(to: sockaddr.self).baseAddress, UInt32(MemoryLayout<sockaddr_in>.size))
                    }
                }
                if ret < 0 { GenericTools.perror("sendto") }
                
                print("après ICMP-")
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                if ret < 0 {
                    GenericTools.perror("recvfrom")
                    continue
                }
                
                
                
            } while s != nil
            
            close(self.s!)
            //                } // DispatchQueue.global
        }
    }
    
    public func stop() {
        s = nil
        //        if let timer = timer {
        //            timer.invalidate()
        //            self.timer = nil
        //}
        //}
        
    }
    
}

struct DetailSwiftUIView: View {
    public let ts = TimeSeries()
    
    public let view: UIView
    
    public var pingloop: PingLoop? = nil
    
    var body: some View {
        ScrollView {
            VStack {
                GeometryReader { geom in
                    SpriteView(scene: {
                        print("(re-)create scene")
                        let scene = SKScene()
                        scene.size = CGSize(width: geom.size.width, height: 300)
                        scene.scaleMode = .fill
                        let chart_node = SKChartNode(ts: ts, full_size: CGSize(width: geom.size.width, height: 300), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: nil)
                        scene.addChild(chart_node)
                        chart_node.registerGestureRecognizers(view: view, delta: 40)
                        chart_node.position = CGPoint(x: 0, y: 0)
                        ts.add(TimeSeriesElement(date: Date(), value: 5.0))
                        return scene
                    }())
                }
                .frame(minWidth: 0, idealWidth: UIScreen.main.bounds.size.width, maxWidth: .infinity, minHeight: 0, idealHeight: 300, maxHeight: .infinity, alignment: .center)
                
            }
            
            Text("Séparation")
            Button {
            } label: {
                Label("Level 1", systemImage: "rectangle.split.2x2")
            }
        } // ScrollView
        
    }
}

/*
 struct DetailSwiftUIView_Previews: PreviewProvider {
 static var previews: some View {
 DetailSwiftUIView(nil)
 }
 }
 */
