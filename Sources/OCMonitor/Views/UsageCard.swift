import SwiftUI

struct UsageCard: View {
    let window: UsageWindow
    let cost: Double

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
                    Text(String(format: "$%.2f / $%.0f", cost, window.limit))
                        .foregroundStyle(Color.muted)
                        .font(.system(size: 11))
                        .monospacedDigit()
                }
                Spacer()
                Text(String(format: "%.0f%%", ratio * 100))
                    .foregroundStyle(ratio > 0.85 ? Color.red : Color.muted)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
            BarView(ratio: ratio, overThreshold: ratio > 0.85)
        }
    }
}
