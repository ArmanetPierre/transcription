import SwiftUI

struct MeetingReportView: View {
    let project: TranscriptionProject
    var onExportMD: (() -> Void)?
    var onExportPDF: (() -> Void)?

    @State private var isExpanded = true

    var body: some View {
        if let report = project.meetingReport, !report.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerBar

                // Contenu depliable
                if isExpanded {
                    Divider()

                    MarkdownContentView(text: report)
                        .textSelection(.enabled)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.purple.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 0) {
            // Bouton expand/collapse (partie gauche, cliquable)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    // Barre violette a gauche
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.purple)
                        .frame(width: 4)
                        .padding(.trailing, 12)

                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)

                    Text("Compte rendu")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .padding(.leading, 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Badge modele
            if let model = project.reportModelUsed {
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
                .padding(.trailing, 8)
            }

            // Menu d'export
            Menu {
                Button {
                    onExportMD?()
                } label: {
                    Label("Markdown (.md)", systemImage: "doc.text")
                }

                Button {
                    onExportPDF?()
                } label: {
                    Label("PDF (.pdf)", systemImage: "doc.richtext")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .padding(.trailing, 4)

            // Chevron expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
