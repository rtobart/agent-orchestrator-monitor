import SwiftUI

@main
struct OCMonitorApp: App {
    private let viewModel = MonitorViewModel(db: SQLiteDatabaseService())

    var body: some Scene {
        MenuBarExtra("Uso", systemImage: "chart.bar.fill") {
            ContentView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
