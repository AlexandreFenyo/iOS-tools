
import Foundation

public struct TimeSeriesElement {
    public let date : Date
    public let value : Float
}

public protocol TimeSeriesReceiver {
}

public actor TimeSeries {
    // Ordered data keys (dates)
    private var keys: [Date] = []

    public init() { }

    public func register(_ receiver: TimeSeriesReceiver) {
    }

    public func add(_ tse: TimeSeriesElement) async {
    }

    // Ordered array of every elements
}
