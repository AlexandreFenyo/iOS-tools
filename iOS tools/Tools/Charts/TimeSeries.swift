//
//  TimeSeries.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 24/05/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

public struct TimeSeriesElement {
    public let date : Date
    public let value : Float
}

public protocol TimeSeriesReceiver {
    func cbNewData(ts: TimeSeries, tse: TimeSeriesElement) async
}

public actor TimeSeries {
    private var receivers: [TimeSeriesReceiver] = []
    private var data: [Date: TimeSeriesElement] = [:]
    // Ordered data keys (dates)
    private var keys: [Date] = []

    public init() { }

    public func register(_ receiver: TimeSeriesReceiver) {
        // acceptable uniquement car on utilise un seul receiver dans cette app, et ça permet d'éviter les références croisées vers les SKChartNode plus utilisés
        unRegisterAll()

        receivers.append(receiver)
    }

    public func unRegisterAll() {
        receivers.removeAll()
    }

    public func add(_ tse: TimeSeriesElement) async {
        // Update backing store
        if data[tse.date] != nil { return }
        data[tse.date] = tse
        let next_date = keys.first { (date) in date > tse.date }
        keys.insert(tse.date, at: next_date != nil ? keys.firstIndex(of: next_date!)! : keys.count)

        // Signal about new value
        for receiver in receivers { await receiver.cbNewData(ts: self, tse: tse) }
    }

    // Ordered array of every elements
    public func getElements() -> [TimeSeriesElement] {
        var elts : [TimeSeriesElement] = []
        for key in keys { elts.append(data[key]!) }
        return elts
    }
}
