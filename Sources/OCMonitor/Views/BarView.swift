import SwiftUI

struct BarView: View {
    let ratio: Double
    let overThreshold: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray)
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(overThreshold ? Color.red : Color.blue)
                    .frame(width: max(geo.size.width * ratio, ratio > 0 ? 4 : 0), height: 4)
            }
        }
        .frame(height: 4)
    }
}
