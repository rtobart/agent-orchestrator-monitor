import SwiftUI

@Observable
@MainActor
final class MonitorViewModel: @unchecked Sendable {
    private let db: DatabaseServiceProtocol
    private let discovery: ProviderDiscoveryProtocol
    private let codexUsage: CodexUsageServiceProtocol

    var providers: [Provider] = []
    var costs: [String: [String: Double]] = [:]  // [providerId: [windowKey: cost]]
    var modelUsage: [String: [String: [ModelUsage]]] = [:]
    var codexModelUsage: [String: [ModelUsage]] = [:]
    var codexState: CodexUsageState = .loading
    private var timer: Timer?

    init(
        discovery: ProviderDiscoveryProtocol = ProviderDiscovery(),
        db: DatabaseServiceProtocol = SQLiteDatabaseService(),
        codexUsage: CodexUsageServiceProtocol = CodexUsageService()
    ) {
        self.discovery = discovery
        self.db = db
        self.codexUsage = codexUsage
        self.providers = discovery.discover()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        for provider in providers {
            var c: [String: Double] = [:]
            var models: [String: [ModelUsage]] = [:]
            for w in provider.windows {
                c[w.key] = db.fetchCost(providerId: provider.id, since: w.seconds)
                models[w.key] = db.fetchModelUsage(providerId: provider.id, since: w.seconds)
            }
            costs[provider.id] = c
            modelUsage[provider.id] = models
        }
        Task {
            do {
                let snapshot = try await codexUsage.fetch()
                codexState = .available(snapshot)
                var usage: [String: [ModelUsage]] = [:]
                for window in snapshot.windows {
                    if let minutes = window.durationMinutes {
                        usage[window.id] = db.fetchModelUsage(providerId: "openai", since: minutes * 60)
                    }
                }
                codexModelUsage = usage
            } catch {
                codexState = .unavailable(error.localizedDescription)
            }
        }
    }

    func cost(for providerId: String, window: UsageWindow) -> Double {
        costs[providerId]?[window.key] ?? 0
    }


    func models(for providerId: String, window: UsageWindow) -> [ModelUsage] {
        modelUsage[providerId]?[window.key] ?? []
    }
}
