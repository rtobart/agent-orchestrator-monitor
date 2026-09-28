import SwiftUI

struct ModelUsageBreakdownView: View {
    let models: [ModelUsage]
    let showsCost: Bool
    let note: String

    private var totalRequests: Int {
        models.reduce(0) { $0 + $1.requestCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(models) { model in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(model.modelID)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(String(format: "%.1f%% req.", model.percentOfRequests(total: totalRequests)))
                                .monospacedDigit()
                    }
                    HStack {
                        Text("\(model.requestCount) requests estimados")
                        Spacer()
                        if showsCost {
                            Text(String(format: "$%.2f", model.cost))
                        }
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(Color.muted)
                }
            }

            Text(note)
                .font(.system(size: 8))
                .foregroundStyle(Color.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 8)
    }
}
