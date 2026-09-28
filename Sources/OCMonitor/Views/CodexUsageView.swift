import SwiftUI

struct CodexUsageView: View {
    let state: CodexUsageState
    let modelUsage: [String: [ModelUsage]]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("OpenAI Codex (OAuth)")
                    .foregroundStyle(.white)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            switch state {
            case .loading:
                Text("Consultando cuota local…")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.muted)
            case .unavailable(let message):
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.muted)
            case .available(let snapshot):
                ForEach(snapshot.windows) { window in
                    CodexWindowView(window: window, models: modelUsage[window.id] ?? [])
                }
            }
        }
    }
}

private struct CodexWindowView: View {
    let window: CodexUsageWindow
    let models: [ModelUsage]
    @ViewState private var showsModels = false

    var body: some View {
        let ratio = Double(window.usedPercent) / 100
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(window.label)
                        .foregroundStyle(.white)
                        .font(.system(size: 12, weight: .medium))
                    Text(resetText)
                        .foregroundStyle(Color.muted)
                        .font(.system(size: 10))
                }
                Spacer()
                Text("\(window.usedPercent)% usado")
                    .foregroundStyle(ratio > 0.85 ? Color.red : Color.muted)
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
            BarView(ratio: ratio, overThreshold: ratio > 0.85)
            if !models.isEmpty {
                Toggle("Detalle local por modelo", isOn: $showsModels)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.muted)
                if showsModels {
                    ModelUsageBreakdownView(
                        models: models,
                        showsCost: false,
                        note: "Inferencia sobre requests OpenCode locales; OpenAI no expone cuota por modelo."
                    )
                }
            }
        }
    }

    private var resetText: String {
        guard let resetsAt = window.resetsAt else { return "Reinicio no informado" }
        return "Reinicia \(resetsAt.formatted(.relative(presentation: .named)))"
    }
}
