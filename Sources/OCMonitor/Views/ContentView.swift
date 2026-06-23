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
    @State var viewModel: MonitorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Uso de OpenCode")
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

            // Cards
            VStack(spacing: 10) {
                ForEach(viewModel.windows) { w in
                    UsageCard(window: w, cost: viewModel.costs[w.key] ?? 0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider().overlay(Color.gray.opacity(0.15))

            // Footer
            HStack {
                Spacer()
                Button("Salir") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 10))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 280)
        .background(Color.bg)
    }
}
