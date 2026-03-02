import SwiftData
import SwiftUI

@main
struct TranscriptionApp: App {
    @State private var listVM = TranscriptionListVM()

    init() {
        // Arreter le serveur Ollama si lance par l'app a la fermeture
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            OllamaService.stopServer()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(listVM: listVM)
        }
        .modelContainer(for: TranscriptionProject.self)

        Settings {
            SettingsView()
        }

        MenuBarExtra {
            MenuBarView(listVM: listVM)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: listVM.isProcessing ? "waveform.circle.fill" : "waveform.circle")
                if listVM.isProcessing {
                    if let remaining = listVM.estimationService.shortFormattedRemaining {
                        Text(remaining)
                            .font(.caption.monospacedDigit())
                    } else {
                        Text("\(Int(listVM.currentProject?.progressPercent ?? 0))%")
                            .font(.caption.monospacedDigit())
                    }
                }
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
