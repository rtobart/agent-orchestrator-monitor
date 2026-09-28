import Foundation

struct CodexUsageSnapshot: Equatable, Sendable {
    let windows: [CodexUsageWindow]
}

struct CodexUsageWindow: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let usedPercent: Int
    let durationMinutes: Int?
    let resetsAt: Date?
}

enum CodexUsageState: Equatable, Sendable {
    case loading
    case available(CodexUsageSnapshot)
    case unavailable(String)
}
