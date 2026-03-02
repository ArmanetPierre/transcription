import SwiftUI

struct ExportSheet: View {
    let project: TranscriptionProject
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .txt
    @State private var preview = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Exporter la transcription")
                .font(.title2.bold())

            Picker("Format", selection: $selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)

            // Preview
            GroupBox("Apercu") {
                ScrollView {
                    Text(preview)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
            }
            .frame(height: 200)

            HStack {
                Button("Annuler") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Enregistrer...") {
                    saveFile()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 600)
        .onAppear { updatePreview() }
        .onChange(of: selectedFormat) { _, _ in updatePreview() }
    }

    private func updatePreview() {
        let full = ExportService.export(project: project, format: selectedFormat)
        // Montrer seulement les 20 premieres lignes
        let lines = full.components(separatedBy: "\n")
        if lines.count > 20 {
            preview = lines.prefix(20).joined(separator: "\n") + "\n\n... (\(lines.count) lignes au total)"
        } else {
            preview = full
        }
    }

    private func saveFile() {
        let content = ExportService.export(project: project, format: selectedFormat)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(project.title).\(selectedFormat.fileExtension)"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
        dismiss()
    }
}
