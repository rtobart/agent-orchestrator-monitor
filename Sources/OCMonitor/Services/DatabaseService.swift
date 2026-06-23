import Foundation
import SQLite3

// MARK: - Protocol

protocol DatabaseServiceProtocol: Sendable {
    func fetchCost(since seconds: Int) -> Double
}

// MARK: - SQLite Implementation

final class SQLiteDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
    private let dbPath: String

    init(dbPath: String = NSHomeDirectory() + "/.local/share/opencode/opencode.db") {
        self.dbPath = dbPath
    }

    func fetchCost(since seconds: Int) -> Double {
        guard let db = open() else { return 0 }
        defer { sqlite3_close(db) }
        let sql = """
            SELECT COALESCE(SUM(cost), 0) FROM session
            WHERE time_created > (strftime('%s','now') - \(seconds)) * 1000
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

// MARK: - Mock (for testing/previews)

final class MockDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
    var costs: [Int: Double] = [:]

    func fetchCost(since seconds: Int) -> Double {
        costs[seconds] ?? 0
    }
}
