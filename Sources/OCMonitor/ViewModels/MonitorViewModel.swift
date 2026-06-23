import SwiftUI

@Observable
final class MonitorViewModel: @unchecked Sendable {
    private let db: DatabaseServiceProtocol
    private let discovery: ProviderDiscoveryProtocol

    var providers: [Provider] = []
    var costs: [String: [String: Double]] = [:]  // [providerId: [windowKey: cost]]
    private var timer: Timer?

    init(
        discovery: ProviderDiscoveryProtocol = ProviderDiscovery(),
        db: DatabaseServiceProtocol = SQLiteDatabaseService()
    ) {
        self.discovery = discovery
        self.db = db
        self.providers = discovery.discover()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        for provider in providers {
            var c: [String: Double] = [:]
            for w in provider.windows {
                c[w.key] = db.fetchCost(providerId: provider.id, since: w.seconds)
            }
            costs[provider.id] = c
        }
    }

    func cost(for providerId: String, window: UsageWindow) -> Double {
        costs[providerId]?[window.key] ?? 0
    }
}
