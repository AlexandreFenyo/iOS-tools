//
//  TimeSeries.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 24/05/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

public struct ChartUnits {
    public static let RTT = ChartUnits(base: "µs", base_x10: "ms", base_x100: "s", base_x1000: "error")
    public static let BANDWIDTH = ChartUnits(base: "bit/s", base_x10: "kbit/s", base_x100: "Mbit/s", base_x1000: "Gbit/s")
    public let base: String
    public let base_x10: String
    public let base_x100: String
    public let base_x1000: String
}

public struct TimeSeriesElement {
    public let date : Date
    public let value : Float
}

public protocol TimeSeriesReceiver {
    func cbNewData(ts: TimeSeries, tse: TimeSeriesElement?) async
}

let AVERAGE_EXPONENT: Float = 0.3

public actor TimeSeries {
    private var receivers: [TimeSeriesReceiver] = []
    private var data: [Date: TimeSeriesElement] = [:]
    // Ordered data keys (dates)
    private var keys: [Date] = []
    private var average: Float = 0.0
    
    private var units: ChartUnits = .RTT
    
    public init() { }
    
    public func getAverage() -> Float {
        return average
    }
    
    public func setUnits(units: ChartUnits) {
        self.units = units
    }
    
    public func getUnits() -> ChartUnits {
        return units
    }
    
    public func register(_ receiver: TimeSeriesReceiver) {
        receivers.append(receiver)
    }
    
    public func add(_ tse: TimeSeriesElement) async {
        average = average * AVERAGE_EXPONENT + tse.value * (1.0 - AVERAGE_EXPONENT)
        
        /*
        print("XXXX TimeSeries.add()")
        var newtsedate: Date?
        if foo == 0 {
            foo += 1
            newtsedate = Date(timeInterval: 1.5, since: tse.date)
        } else {
            newtsedate = tse.date
        }
        let newtse = TimeSeriesElement(date: newtsedate!, value: tse.value)
        // Update backing store
        if data[newtse.date] != nil { return }
        data[newtse.date] = newtse
        let next_date = keys.first { (date) in date > newtse.date }
        keys.insert(newtse.date, at: next_date != nil ? keys.firstIndex(of: next_date!)! : keys.count)
        // Signal about new value
        for receiver in receivers { await receiver.cbNewData(ts: self, tse: newtse) }
*/
        
        
        // Update backing store
        if data[tse.date] != nil { return }
        data[tse.date] = tse
        let next_date = keys.first { (date) in date > tse.date }
        keys.insert(tse.date, at: next_date != nil ? keys.firstIndex(of: next_date!)! : keys.count)
        
        // Signal about new value
        for receiver in receivers { await receiver.cbNewData(ts: self, tse: tse) }
    }
    
    public func removeAll() async {
        // Update backing store
        data.removeAll()
        keys.removeAll()
        average = 0.0
        // Signal about news values
        for receiver in receivers { await receiver.cbNewData(ts: self, tse: nil) }
    }
    
    // Ordered array of every elements
    public func getElements() -> [TimeSeriesElement] {
        var elts : [TimeSeriesElement] = []
        for key in keys { elts.append(data[key]!) }
        return elts
    }
    
    public func count() -> Int {
        return keys.count
    }
}
