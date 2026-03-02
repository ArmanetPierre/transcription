import SwiftUI

struct TranscriptionRow: View {
    let project: TranscriptionProject
    var estimationService: EstimationService?

    var body: some View {
        HStack(spacing: 10) {
            statusIcon
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(project.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if project.audioDurationSec > 0 {
                        Text(project.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)

                    if project.status.isProcessing,
                       let estimation = estimationService?.shortFormattedRemaining
                    {
                        Text(estimation)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if project.status.isProcessing {
                ProgressView(value: project.progressPercent, total: 100)
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch project.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .transcribing, .diarizing, .merging:
            Image(systemName: "waveform")
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)
        case .awaitingSpeakerNames:
            Image(systemName: "person.2.fill")
                .foregroundStyle(.orange)
        case .generatingSummary:
            Image(systemName: "brain")
                .foregroundStyle(.purple)
                .symbolEffect(.pulse)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch project.status {
        case .pending:
            "En attente"
        case .transcribing:
            "Transcription \(Int(project.progressPercent))%"
        case .diarizing:
            "Diarisation \(Int(project.progressPercent))%"
        case .merging:
            "Attribution..."
        case .awaitingSpeakerNames:
            "Identification speakers"
        case .generatingSummary:
            "Synthese en cours..."
        case .completed:
            "\(project.uniqueSpeakers.count) speaker\(project.uniqueSpeakers.count > 1 ? "s" : "")"
        case .failed:
            "Erreur"
        }
    }

    private var statusColor: Color {
        switch project.status {
        case .completed: .green
        case .failed: .red
        case .pending: .secondary
        case .awaitingSpeakerNames: .orange
        case .generatingSummary: .purple
        default: .blue
        }
    }
}
