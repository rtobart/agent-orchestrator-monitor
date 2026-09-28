import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Protocol

protocol DatabaseServiceProtocol: Sendable {
    func fetchCost(since seconds: Int) -> Double
    func fetchCost(providerId: String, since seconds: Int) -> Double
    func fetchModelUsage(providerId: String, since seconds: Int) -> [ModelUsage]
}

// MARK: - SQLite Implementation

final class SQLiteDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
    private let dbPath: String

    init(dbPath: String = NSHomeDirectory() + "/.local/share/opencode/opencode.db") {
        self.dbPath = dbPath
    }

    func fetchCost(since seconds: Int) -> Double {
        _fetchCost(providerId: nil, since: seconds)
    }

    func fetchCost(providerId: String, since seconds: Int) -> Double {
        _fetchCost(providerId: providerId, since: seconds)
    }

    func fetchModelUsage(providerId: String, since seconds: Int) -> [ModelUsage] {
        guard let db = open() else { return [] }
        defer { sqlite3_close(db) }
        let sql = """
            SELECT json_extract(data, '$.modelID') AS model_id,
                   COUNT(*) AS request_count,
                   COALESCE(SUM(json_extract(data, '$.cost')), 0) AS cost
            FROM message
            WHERE time_created > (strftime('%s','now') - ?) * 1000
              AND json_valid(data)
              AND json_extract(data, '$.providerID') = ?
              AND json_extract(data, '$.modelID') IS NOT NULL
              AND json_extract(data, '$.role') = 'assistant'
            GROUP BY model_id
            ORDER BY cost DESC, request_count DESC
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int64(stmt, 1, Int64(seconds))
        sqlite3_bind_text(stmt, 2, providerId, -1, sqliteTransient)

        var result: [ModelUsage] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let text = sqlite3_column_text(stmt, 0) else { continue }
            result.append(ModelUsage(
                modelID: String(cString: text),
                requestCount: Int(sqlite3_column_int64(stmt, 1)),
                cost: sqlite3_column_double(stmt, 2)
            ))
        }
        return result
    }

    private func _fetchCost(providerId: String?, since seconds: Int) -> Double {
        guard let db = open() else { return 0 }
        defer { sqlite3_close(db) }

        let providerFilter: String
        if let pid = providerId {
            providerFilter = "AND model LIKE '%\"providerID\":\"\(pid)\"%'"
        } else {
            providerFilter = ""
        }

        let sql = """
            SELECT COALESCE(SUM(cost), 0) FROM session
            WHERE time_created > (strftime('%s','now') - \(seconds)) * 1000
            \(providerFilter)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        sqlite3_step(stmt)
        return sqlite3_column_double(stmt, 0)
    }

    private func open() -> OpaquePointer? {
        var db: OpaquePointer?
        sqlite3_open(dbPath, &db)
        return db
    }
}

// MARK: - Mock

final class MockDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
    var costs: [Int: Double] = [:]
    var providerCosts: [String: [Int: Double]] = [:]
    var modelUsage: [String: [Int: [ModelUsage]]] = [:]

    func fetchCost(since seconds: Int) -> Double {
        costs[seconds] ?? 0
    }

    func fetchCost(providerId: String, since seconds: Int) -> Double {
        providerCosts[providerId]?[seconds] ?? 0
    }


    func fetchModelUsage(providerId: String, since seconds: Int) -> [ModelUsage] {
        modelUsage[providerId]?[seconds] ?? []
    }
}
