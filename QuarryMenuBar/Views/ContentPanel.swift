import SwiftUI

/// Root content view for the menu bar panel.
///
/// Manages daemon lifecycle (start on appear, stop on disappear)
/// and routes to the appropriate view based on daemon state.
struct ContentPanel: View {

    // MARK: Internal

    let daemon: DaemonManager

    @Bindable var searchViewModel: SearchViewModel

    let databaseManager: DatabaseManager
    let onDatabaseSwitch: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            statusContent
                .animation(.easeInOut(duration: 0.15), value: daemon.state)
            Divider()
            footer
        }
        .task {
            daemon.start()
        }
    }

    // MARK: Private

    private var header: some View {
        HStack {
            Image(systemName: "doc.text.magnifyingglass")
                .foregroundStyle(.secondary)
            Text("Quarry")
                .font(.headline)
            DatabasePickerView(
                databaseManager: databaseManager,
                onSwitch: onDatabaseSwitch
            )
            Spacer()
            statusBadge
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch daemon.state {
        case .stopped:
            Label("Stopped", systemImage: "circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .starting:
            Label("Starting…", systemImage: "circle.dotted")
                .font(.caption)
                .foregroundStyle(.orange)
        case .running:
            Label("Running", systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case let .error(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        switch daemon.state {
        case .stopped:
            VStack(spacing: 12) {
                Image(systemName: "stop.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text("Backend Stopped")
                    .font(.headline)
                Text("The search backend is not running.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Start") {
                    daemon.start()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            Spacer()
        case .starting:
            VStack(spacing: 8) {
                ProgressView("Starting Quarry…")
                Text("Launching the search backend.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            Spacer()
        case .running:
            SearchPanel(viewModel: searchViewModel)
        case let .error(message):
            ErrorStateView(message: message) {
                daemon.restart()
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Quit") {
                daemon.stop()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
