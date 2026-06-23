import SwiftUI

@Observable
final class MonitorViewModel: @unchecked Sendable {
    private let db: DatabaseServiceProtocol

    var windows: [UsageWindow] = UsageWindow.presets
    var costs: [String: Double] = [:]
    private var timer: Timer?

    init(db: DatabaseServiceProtocol) {
        self.db = db
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        var c: [String: Double] = [:]
        for w in windows {
            c[w.key] = db.fetchCost(since: w.seconds)
        }
        costs = c
    }
}
