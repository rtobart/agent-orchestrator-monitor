import Foundation

struct UsageWindow: Identifiable {
    let id = UUID()
    let label: String
    let key: String
    let seconds: Int
    let limit: Double

    static let presets: [UsageWindow] = [
        .init(label: "Últimas 5 horas", key: "5h", seconds: 5 * 3600, limit: 12),
        .init(label: "Esta semana",     key: "7d", seconds: 7 * 86400, limit: 30),
        .init(label: "Este mes",        key: "30d", seconds: 30 * 86400, limit: 60),
    ]
}
