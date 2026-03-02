import SwiftUI

struct ProgressOverlay: View {
    let project: TranscriptionProject
    var summaryError: String?
    var ollamaService: OllamaService?
    var estimationService: EstimationService?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: statusIcon)
                .font(.system(size: 50))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse, isActive: project.status.isProcessing)

            Text(project.status.label)
                .font(.title2.bold())

            if project.status == .generatingSummary {
                if let ollama = ollamaService, ollama.isPulling {
                    // Telechargement du modele en cours
                    VStack(spacing: 12) {
                        ProgressView(value: ollama.pullProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 300)

                        Text("Telechargement du modele \(ollama.pullModelName ?? "")... \(Int(ollama.pullProgress * 100))%")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Progression indeterminee pour la synthese
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)

                    Text("Analyse des interventions avec Ollama...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else if project.status.isProcessing {
                ProgressView(value: project.progressPercent, total: 100)
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                HStack(spacing: 12) {
                    Text("\(Int(project.progressPercent))%")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if let estimation = estimationService?.formattedRemaining {
                        Text(estimation)
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if project.status == .pending {
                Text("En attente de traitement...")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusIcon: String {
        switch project.status {
        case .generatingSummary:
            "brain"
        default:
            "waveform"
        }
    }
}
