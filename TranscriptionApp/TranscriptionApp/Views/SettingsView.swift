import SwiftUI

struct SettingsView: View {
    @AppStorage("hf_token") private var hfToken = ""
    @AppStorage("default_model") private var defaultModel = WhisperModel.largeV3Turbo.rawValue
    @AppStorage("python_path") private var pythonPath = PythonBridge.defaultPythonPath
    @AppStorage("script_path") private var scriptPath = PythonBridge.defaultScriptPath
    @AppStorage("default_diarization") private var defaultDiarization = true
    @AppStorage("ollama_model") private var ollamaModel = OllamaModel.llama3_1.rawValue

    @State private var ollamaStatus: OllamaStatus = .unknown

    var body: some View {
        Form {
            Section("HuggingFace") {
                SecureField("Token HuggingFace", text: $hfToken)
                    .help("Requis pour telecharger les modeles pyannote (diarisation)")
                Text("Creez un token sur huggingface.co/settings/tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Transcription") {
                Picker("Modele par defaut", selection: $defaultModel) {
                    ForEach(WhisperModel.allCases) { model in
                        Text(model.displayName).tag(model.rawValue)
                    }
                }

                Toggle("Diarisation par defaut", isOn: $defaultDiarization)
                    .help("Identifier automatiquement les differents interlocuteurs")
            }

            Section("Synthese LLM (Ollama)") {
                Picker("Modele Ollama", selection: $ollamaModel) {
                    ForEach(OllamaModel.allCases) { model in
                        Text(model.displayName).tag(model.rawValue)
                    }
                }
                .help("Modele utilise pour generer les syntheses par speaker")

                HStack(spacing: 8) {
                    switch ollamaStatus {
                    case .unknown:
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                        Text("Statut inconnu")
                            .foregroundStyle(.secondary)
                    case .checking:
                        ProgressView()
                            .controlSize(.small)
                        Text("Verification...")
                            .foregroundStyle(.secondary)
                    case .available:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Ollama disponible")
                    case .unavailable:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Ollama non disponible")
                    }

                    Spacer()

                    Button("Verifier") {
                        checkOllama()
                    }
                    .controlSize(.small)
                }
                .font(.caption)

                Text("Lancez 'ollama serve' pour activer la synthese automatique")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Chemins Python") {
                HStack {
                    TextField("Python", text: $pythonPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Parcourir") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            pythonPath = url.path
                        }
                    }
                }

                HStack {
                    TextField("Script", text: $scriptPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Parcourir") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        panel.allowedContentTypes = [.pythonScript]
                        if panel.runModal() == .OK, let url = panel.url {
                            scriptPath = url.path
                        }
                    }
                }

                // Status check
                HStack {
                    if FileManager.default.fileExists(atPath: pythonPath) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Python trouve")
                    } else {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        Text("Python introuvable")
                    }
                }
                .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500)
        .padding()
        .onAppear {
            checkOllama()
        }
    }

    private func checkOllama() {
        ollamaStatus = .checking
        Task {
            let service = OllamaService()
            let available = await service.isAvailable()
            await MainActor.run {
                ollamaStatus = available ? .available : .unavailable
            }
        }
    }

    private enum OllamaStatus {
        case unknown, checking, available, unavailable
    }
}
