import Foundation

@main
enum CodexRateLimitParserTests {
    static func main() throws {
        try parsesPrimaryAndSecondaryWindows()
        try omitsMissingWindow()
        try clampsPercentageForSafePresentation()
        rejectsProtocolError()
        try excludesOpenAIOAuthFromEstimatedSpendProviders()
        distinguishesOpenCodeZenAndGo()
        calculatesModelShareOfSharedWindow()
        calculatesModelShareOfRequests()
        print("✅ 8 pruebas de integración pasaron")
    }

    private static func parsesPrimaryAndSecondaryWindows() throws {
        let data = Data(#"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":23,"windowDurationMins":300,"resetsAt":1787000000},"secondary":{"usedPercent":61,"windowDurationMins":10080,"resetsAt":1787600000}}}}"#.utf8)
        let snapshot = try CodexRateLimitParser.parse(data)
        expect(snapshot.windows.count == 2, "debe incluir ambas ventanas")
        expect(snapshot.windows[0].label == "5 horas", "debe nombrar la ventana primaria")
        expect(snapshot.windows[0].usedPercent == 23, "debe conservar el porcentaje")
        expect(snapshot.windows[0].resetsAt == Date(timeIntervalSince1970: 1_787_000_000), "debe convertir resetsAt")
        expect(snapshot.windows[1].label == "7 días", "debe nombrar la ventana semanal")
    }

    private static func omitsMissingWindow() throws {
        let data = Data(#"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":8,"windowDurationMins":300,"resetsAt":null},"secondary":null}}}"#.utf8)
        let snapshot = try CodexRateLimitParser.parse(data)
        expect(snapshot.windows.count == 1, "debe omitir ventanas nulas")
        expect(snapshot.windows[0].resetsAt == nil, "debe aceptar reinicio nulo")
    }

    private static func clampsPercentageForSafePresentation() throws {
        let data = Data(#"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":140,"windowDurationMins":300},"secondary":{"usedPercent":-4,"windowDurationMins":10080}}}}"#.utf8)
        let snapshot = try CodexRateLimitParser.parse(data)
        expect(snapshot.windows.map(\.usedPercent) == [100, 0], "debe limitar porcentajes a 0...100")
    }

    private static func rejectsProtocolError() {
        let data = Data(#"{"id":2,"error":{"code":-32000,"message":"not logged in"}}"#.utf8)
        do {
            _ = try CodexRateLimitParser.parse(data)
            fail("debe rechazar errores del protocolo")
        } catch { }
    }

    private static func excludesOpenAIOAuthFromEstimatedSpendProviders() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ocmonitor-auth-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let auth = Data(#"{"openai":{"type":"oauth","access":"redacted"},"github-copilot":{"type":"oauth","access":"redacted"}}"#.utf8)
        try auth.write(to: url)

        let providers = ProviderDiscovery(authPath: url.path).discover()

        expect(providers.map(\.id) == ["github-copilot"], "OpenAI OAuth no debe mostrarse como gasto estimado")
    }

    private static func distinguishesOpenCodeZenAndGo() {
        let go = Provider.defaults(for: "opencode-go")
        let zen = Provider.defaults(for: "opencode")
        expect(go.name == "OpenCode Go", "debe rotular correctamente OpenCode Go")
        expect(go.windows.allSatisfy { $0.limit > 0 }, "Go debe mostrar sus topes de suscripción")
        expect(zen.name == "OpenCode Zen", "debe rotular correctamente OpenCode Zen")
        expect(zen.windows.allSatisfy { $0.limit == 0 }, "Zen no debe inventar topes de suscripción")
    }

    private static func calculatesModelShareOfSharedWindow() {
        let usage = ModelUsage(modelID: "deepseek-v4-pro", requestCount: 12, cost: 3)
        expect(usage.percentOfSharedLimit(12) == 25, "debe calcular el aporte al límite compartido")
        expect(usage.percentOfSharedLimit(0) == nil, "no debe inventar porcentaje sin límite")
    }

    private static func calculatesModelShareOfRequests() {
        let usage = ModelUsage(modelID: "model-a", requestCount: 25, cost: 0)
        expect(usage.percentOfRequests(total: 100) == 25, "debe inferir proporción por requests")
        expect(usage.percentOfRequests(total: 0) == 0, "debe tolerar una ventana vacía")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fail(message) }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("❌ \(message)\n".utf8))
        exit(1)
    }
}
