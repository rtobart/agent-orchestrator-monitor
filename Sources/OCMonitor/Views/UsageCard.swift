import SwiftUI

struct UsageCard: View {
    let window: UsageWindow
    let cost: Double
    let models: [ModelUsage]
    let showsModelCost: Bool
    let modelUsageNote: String
    @ViewState private var showsModels = false

    var ratio: Double {
        window.limit > 0 ? min(cost / window.limit, 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(window.label)
                        .foregroundStyle(.white)
                        .font(.system(size: 12, weight: .medium))
                    Text(usageText)
                        .foregroundStyle(Color.muted)
                        .font(.system(size: 11))
                        .monospacedDigit()
                }
                Spacer()
                if window.limit > 0 {
                    Text(String(format: "%.0f%%", ratio * 100))
                        .foregroundStyle(ratio > 0.85 ? Color.red : Color.muted)
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                }
            }
            if window.limit > 0 {
                BarView(ratio: ratio, overThreshold: ratio > 0.85)
            }
            if !models.isEmpty {
                Toggle("Detalle por modelo", isOn: $showsModels)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.muted)
                if showsModels {
                    ModelUsageBreakdownView(
                        models: models,
                        showsCost: showsModelCost,
                        note: modelUsageNote
                    )
                }
            }
        }
    }

    private var usageText: String {
        if window.limit > 0 {
            return String(format: "$%.2f / $%.0f", cost, window.limit)
        }
        return String(format: "$%.2f consumidos", cost)
    }
}
