import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Text("EDFViewer macOS")
                .font(.headline)
            Text("SwiftUI front-end scaffold for EDF/BDF viewing.")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 420)
    }
}
