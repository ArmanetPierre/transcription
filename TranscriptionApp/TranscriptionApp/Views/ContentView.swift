import SwiftData
import SwiftUI

struct ContentView: View {
    @Bindable var listVM: TranscriptionListVM
    @State private var selectedProject: TranscriptionProject?

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: listVM, selection: $selectedProject)
        } detail: {
            if let project = selectedProject {
                TranscriptionDetail(
                    project: project,
                    estimationService: listVM.currentProject?.id == project.id ? listVM.estimationService : nil
                )
            } else {
                ContentUnavailableView(
                    "Aucune transcription selectionnee",
                    systemImage: "waveform",
                    description: Text("Importez un fichier audio ou selectionnez une transcription existante.")
                )
            }
        }
        .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        .frame(minWidth: 900, minHeight: 600)
    }
}
