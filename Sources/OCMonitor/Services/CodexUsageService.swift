import Foundation

protocol CodexUsageServiceProtocol: Sendable {
    func fetch() async throws -> CodexUsageSnapshot
}

enum CodexUsageError: LocalizedError {
    case executableNotFound
    case launchFailed(String)
    case timeout
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "No se encontró Codex instalado."
        case .launchFailed(let detail):
            return "No se pudo iniciar Codex: \(detail)"
        case .timeout:
            return "Codex no respondió a tiempo."
        case .invalidResponse:
            return "Codex devolvió una respuesta no reconocida."
        case .server(let message):
            return message
        }
    }
}

enum CodexRateLimitParser {
    static func parse(_ data: Data) throws -> CodexUsageSnapshot {
        let response = try JSONDecoder().decode(Response.self, from: data)
        if let message = response.error?.message {
            throw CodexUsageError.server(message)
        }
        guard let limits = response.result?.rateLimits else {
            throw CodexUsageError.invalidResponse
        }

        let candidates = [("primary", limits.primary), ("secondary", limits.secondary)]
        let windows = candidates.compactMap { id, window -> CodexUsageWindow? in
            guard let window else { return nil }
            let duration = window.windowDurationMins
            return CodexUsageWindow(
                id: id,
                label: label(for: duration, fallback: id),
                usedPercent: min(max(window.usedPercent, 0), 100),
                durationMinutes: duration,
                resetsAt: window.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            )
        }
        guard !windows.isEmpty else { throw CodexUsageError.invalidResponse }
        return CodexUsageSnapshot(windows: windows)
    }

    private static func label(for minutes: Int?, fallback: String) -> String {
        guard let minutes else { return fallback == "primary" ? "Ventana principal" : "Ventana secundaria" }
        if minutes % 10_080 == 0 { return "\(minutes / 10_080 * 7) días" }
        if minutes % 1_440 == 0 { return "\(minutes / 1_440) días" }
        if minutes % 60 == 0 { return "\(minutes / 60) horas" }
        return "\(minutes) minutos"
    }

    private struct Response: Decodable {
        let result: ResultPayload?
        let error: ErrorPayload?
    }

    private struct ResultPayload: Decodable { let rateLimits: Limits }
    private struct Limits: Decodable {
        let primary: Window?
        let secondary: Window?
    }
    private struct Window: Decodable {
        let usedPercent: Int
        let windowDurationMins: Int?
        let resetsAt: Int?
    }
    private struct ErrorPayload: Decodable { let message: String }
}

final class CodexUsageService: CodexUsageServiceProtocol, @unchecked Sendable {
    private let transport: CodexAppServerTransport

    init(transport: CodexAppServerTransport = CodexAppServerTransport()) {
        self.transport = transport
    }

    func fetch() async throws -> CodexUsageSnapshot {
        try await Task.detached { [transport] in
            try CodexRateLimitParser.parse(transport.readRateLimits())
        }.value
    }
}

final class CodexAppServerTransport: @unchecked Sendable {
    private let executableURL: URL?
    private let timeout: TimeInterval

    init(executableURL: URL? = CodexAppServerTransport.findExecutable(), timeout: TimeInterval = 8) {
        self.executableURL = executableURL
        self.timeout = timeout
    }

    func readRateLimits() throws -> Data {
        guard let executableURL else { throw CodexUsageError.executableNotFound }

        let process = Process()
        let output = Pipe()
        let input = Pipe()
        let errors = Pipe()
        process.executableURL = executableURL
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = errors

        let completed = DispatchSemaphore(value: 0)
        let state = ResponseBuffer()

        output.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            if state.append(chunk) != nil { completed.signal() }
        }

        do {
            try process.run()
        } catch {
            output.fileHandleForReading.readabilityHandler = nil
            throw CodexUsageError.launchFailed(error.localizedDescription)
        }

        let requests = """
        {"id":1,"method":"initialize","params":{"clientInfo":{"name":"ocmonitor","title":"OC Monitor","version":"1.0.0"},"capabilities":{"experimentalApi":true}}}
        {"id":2,"method":"account/rateLimits/read","params":null}

        """
        input.fileHandleForWriting.write(Data(requests.utf8))

        let waitResult = completed.wait(timeout: .now() + timeout)
        output.fileHandleForReading.readabilityHandler = nil
        input.fileHandleForWriting.closeFile()
        if process.isRunning { process.terminate() }

        guard waitResult == .success else { throw CodexUsageError.timeout }
        let result = state.response
        guard let result else { throw CodexUsageError.invalidResponse }
        return result
    }

    private static func responseId(in data: Data) -> Int? {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["id"] as? Int
    }

    private final class ResponseBuffer: @unchecked Sendable {
        private let lock = NSLock()
        private var buffer = Data()
        private var storedResponse: Data?

        var response: Data? {
            lock.lock()
            defer { lock.unlock() }
            return storedResponse
        }

        func append(_ chunk: Data) -> Data? {
            lock.lock()
            defer { lock.unlock() }
            guard storedResponse == nil else { return storedResponse }
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: 0x0A) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                if CodexAppServerTransport.responseId(in: line) == 2 {
                    storedResponse = line
                    return line
                }
            }
            return nil
        }
    }

    static func findExecutable() -> URL? {
        let candidates = [
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/usr/local/bin/codex",
            "/opt/homebrew/bin/codex"
        ]
        return candidates
            .map(URL.init(fileURLWithPath:))
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}
