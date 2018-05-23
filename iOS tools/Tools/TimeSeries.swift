//
//  TimeSeries.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 24/05/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

struct TimeSeriesElement {
    public let date : Date
    public let value : Float
}

protocol TimeSeriesReceiver {
    func newData(ts: TimeSeries, tse: TimeSeriesElement)
}

class TimeSeries {
    private var receivers: [TimeSeriesReceiver] = []
    private var data: [Date: TimeSeriesElement] = [:]
    // Ordered data keys (dates)
    private var keys: [Date] = []

    public init() { }

    public func register(_ receiver: TimeSeriesReceiver) {
        receivers.append(receiver)
    }

    public func add(_ tse: TimeSeriesElement) {
        // Update backing store
        if data[tse.date] != nil { return }
        data[tse.date] = tse
        let next_date = keys.first { (date) in date > tse.date }
        keys.insert(tse.date, at: next_date != nil ? keys.index(of: next_date!)! : keys.count)

        // Signal about new value
        for receiver in receivers { receiver.newData(ts: self, tse: tse) }
    }

    // Ordered array of every elements
    public func getElements() -> [TimeSeriesElement] {
        var elts : [TimeSeriesElement] = []
        for key in keys { elts.append(data[key]!) }
        return elts
    }
}
