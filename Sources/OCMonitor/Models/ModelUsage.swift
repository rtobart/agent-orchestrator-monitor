import Foundation

struct ModelUsage: Identifiable, Equatable, Sendable {
    var id: String { modelID }
    let modelID: String
    let requestCount: Int
    let cost: Double

    func percentOfSharedLimit(_ limit: Double) -> Double? {
        guard limit > 0 else { return nil }
        return min(max(cost / limit * 100, 0), 100)
    }

    func percentOfRequests(total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(max(Double(requestCount) / Double(total) * 100, 0), 100)
    }
}
