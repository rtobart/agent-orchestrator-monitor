import Foundation

struct Provider: Identifiable, Codable {
    var id: String
    var name: String
    var type: ProviderType
    var windows: [UsageWindow]

    enum ProviderType: String, Codable {
        case opencode
        case githubCopilot = "github-copilot"
        case unknown
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, windows
    }
}

// MARK: - Defaults por provider

extension Provider {
    static func defaults(for key: String) -> Provider {
        switch key {
        case "opencode-go", "opencode":
            return Provider(
                id: key,
                name: "OpenCode Zen",
                type: .opencode,
                windows: [
                    .init(label: "Últimas 5 horas", key: "5h", seconds: 5 * 3600, limit: 12),
                    .init(label: "Esta semana",     key: "7d", seconds: 7 * 86400, limit: 30),
                    .init(label: "Este mes",        key: "30d", seconds: 30 * 86400, limit: 60),
                ]
            )
        case "github-copilot":
            return Provider(
                id: key,
                name: "GitHub Copilot",
                type: .githubCopilot,
                windows: [
                    .init(label: "Esta semana", key: "7d", seconds: 7 * 86400, limit: 2.50),
                    .init(label: "Este mes",    key: "30d", seconds: 30 * 86400, limit: 10),
                ]
            )
        default:
            return Provider(
                id: key,
                name: key,
                type: .unknown,
                windows: [
                    .init(label: "Total", key: "total", seconds: 365 * 86400, limit: 0),
                ]
            )
        }
    }
}
