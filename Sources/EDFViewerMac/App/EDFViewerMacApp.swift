import SwiftUI

@main
struct EDFViewerMacApp: App {
    @StateObject private var viewModel = ViewerViewModel()

    var body: some Scene {
        WindowGroup("EDF Viewer") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}
