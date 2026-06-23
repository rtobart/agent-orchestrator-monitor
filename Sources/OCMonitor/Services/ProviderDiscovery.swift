import Foundation

protocol ProviderDiscoveryProtocol: Sendable {
    func discover() -> [Provider]
}

final class ProviderDiscovery: ProviderDiscoveryProtocol, @unchecked Sendable {
    private let authPath: String

    init(authPath: String? = nil) {
        self.authPath = authPath ?? (NSHomeDirectory() as NSString)
            .appendingPathComponent(".local/share/opencode/auth.json")
    }

    func discover() -> [Provider] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: authPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }

        return json.keys.compactMap { key in
            // Skip "type" metadata fields that might appear
            guard json[key] is [String: Any] else { return nil }
            return Provider.defaults(for: key)
        }
    }
}
