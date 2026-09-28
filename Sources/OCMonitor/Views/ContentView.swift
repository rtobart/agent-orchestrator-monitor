import SwiftUI

// MARK: - Design Tokens

extension Color {
    static let bg     = Color(hex: "#0f1117")
    static let blue   = Color(hex: "#3b82f6")
    static let red    = Color(hex: "#ef4444")
    static let gray   = Color(hex: "#2a2d3a")
    static let muted  = Color(hex: "#6b7280")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Content View

struct ContentView: View {
    @ViewState var viewModel: MonitorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Uso de Agentes")
                    .foregroundStyle(.white)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.muted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider().overlay(Color.gray.opacity(0.15))

            VStack(spacing: 12) {
                    CodexUsageView(state: viewModel.codexState, modelUsage: viewModel.codexModelUsage)

                    Divider().overlay(Color.gray.opacity(0.1))

                    if viewModel.providers.isEmpty {
                        Text("No se detectaron otros providers de OpenCode.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.muted)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                    } else {

                        ForEach(viewModel.providers) { provider in
                            VStack(alignment: .leading, spacing: 6) {
                                // Provider header
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(providerColor(provider.type))
                                        .frame(width: 6, height: 6)
                                    Text(provider.name)
                                        .foregroundStyle(.white)
                                        .font(.system(size: 11, weight: .semibold))
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }

                                // Windows
                                ForEach(provider.windows) { w in
                                    UsageCard(
                                        window: w,
                                        cost: viewModel.cost(for: provider.id, window: w),
                                        models: viewModel.models(for: provider.id, window: w),
                                        showsModelCost: provider.id == "opencode-go" || provider.id == "opencode",
                                        modelUsageNote: modelUsageNote(for: provider)
                                    )
                                }
                            }

                            if provider.id != viewModel.providers.last?.id {
                                Divider().overlay(Color.gray.opacity(0.1))
                            }
                        }
                    }
            }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider().overlay(Color.gray.opacity(0.15))

            HStack {
                Text("\(viewModel.providers.count + 1) fuente(s)")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.muted)
                Spacer()
                Button("Salir") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 10))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 300)
        .background(Color.bg)
    }

    private func providerColor(_ type: Provider.ProviderType) -> Color {
        switch type {
        case .opencode:      return .blue
        case .githubCopilot: return .green
        case .unknown:       return .muted
        }
    }

    private func modelUsageNote(for provider: Provider) -> String {
        switch provider.id {
        case "opencode-go":
            return "Inferencia: proporción de requests locales del modelo dentro de esta ventana."
        case "github-copilot":
            return "Inferencia local por requests; Copilot no expone aquí una cuota por modelo."
        default:
            return "Inferencia local por requests; no representa una cuota individual del proveedor."
        }
    }
}
