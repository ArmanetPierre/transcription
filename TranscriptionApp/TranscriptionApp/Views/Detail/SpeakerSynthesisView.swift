import SwiftUI

struct SpeakerSynthesisView: View {
    let project: TranscriptionProject
    var viewModel: TranscriptionDetailVM

    @State private var expandedSpeakers: Set<String> = []
    @State private var initialized = false

    var body: some View {
        let summaries = project.speakerSummaries

        if !summaries.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(.purple)

                    Text("Summaries")
                        .font(.title3.bold())

                    Text("\(summaries.count) speakers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.secondary.opacity(0.12))
                        )

                    Spacer()

                    if let model = project.summaryModelUsed {
                        HStack(spacing: 4) {
                            Image(systemName: "cpu")
                                .font(.caption2)
                            Text(model)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedSpeakers.count == summaries.count {
                                expandedSpeakers.removeAll()
                            } else {
                                expandedSpeakers = Set(summaries.keys)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: expandedSpeakers.count == summaries.count
                                  ? "chevron.up.2" : "chevron.down.2")
                                .font(.caption2)
                            Text(expandedSpeakers.count == summaries.count ? "Collapse" : "Expand")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }

                // Speaker cards
                ForEach(project.uniqueSpeakers, id: \.self) { speakerLabel in
                    if let summary = summaries[speakerLabel] {
                        speakerCard(
                            speakerLabel: speakerLabel,
                            displayName: project.displayName(for: speakerLabel),
                            summary: summary
                        )
                    }
                }
            }
            .padding(16)
            .onAppear {
                if !initialized {
                    expandedSpeakers = Set(summaries.keys)
                    initialized = true
                }
            }
        }
    }

    // MARK: - Speaker Card

    private func speakerCard(speakerLabel: String, displayName: String, summary: String) -> some View {
        let color = SpeakerColors.color(for: speakerLabel)
        let isExpanded = Binding<Bool>(
            get: { expandedSpeakers.contains(speakerLabel) },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    if newValue {
                        expandedSpeakers.insert(speakerLabel)
                    } else {
                        expandedSpeakers.remove(speakerLabel)
                    }
                }
            }
        )

        return HStack(spacing: 0) {
            // Barre coloree a gauche
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 0) {
                // Header du speaker (toujours visible)
                Button {
                    isExpanded.wrappedValue.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)

                        Text(displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        // Nombre de segments du speaker
                        let count = project.sortedSegments.filter { $0.speakerLabel == speakerLabel }.count
                        Text("\(count) segments")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Contenu (depliable)
                if isExpanded.wrappedValue {
                    Divider()
                        .padding(.horizontal, 12)

                    MarkdownContentView(text: summary)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }

}
