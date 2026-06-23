import Foundation

struct UsageWindow: Identifiable, Codable {
    var id = UUID()
    let label: String
    let key: String
    let seconds: Int
    let limit: Double

    enum CodingKeys: String, CodingKey {
        case label, key, seconds, limit
    }
}
