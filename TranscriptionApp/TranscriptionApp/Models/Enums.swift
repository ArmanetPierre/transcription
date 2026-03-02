import Foundation

enum TranscriptionStatus: String, Codable, CaseIterable {
    case pending
    case transcribing
    case diarizing
    case merging
    case awaitingSpeakerNames
    case generatingSummary
    case completed
    case failed

    var label: String {
        switch self {
        case .pending: "En attente"
        case .transcribing: "Transcription..."
        case .diarizing: "Diarisation..."
        case .merging: "Attribution speakers..."
        case .awaitingSpeakerNames: "Identification des speakers"
        case .generatingSummary: "Generation de la synthese..."
        case .completed: "Termine"
        case .failed: "Erreur"
        }
    }

    var isProcessing: Bool {
        switch self {
        case .transcribing, .diarizing, .merging, .generatingSummary: true
        default: false
        }
    }
}

enum WhisperModel: String, CaseIterable, Identifiable {
    case tiny
    case base
    case small
    case medium
    case largeV3 = "large-v3"
    case largeV3Turbo = "large-v3-turbo"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny: "Tiny (rapide, qualite basse)"
        case .base: "Base"
        case .small: "Small"
        case .medium: "Medium"
        case .largeV3: "Large v3 (meilleure qualite)"
        case .largeV3Turbo: "Large v3 Turbo (recommande)"
        }
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case txt, json, srt, md

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .txt: "Texte (.txt)"
        case .json: "JSON (.json)"
        case .srt: "Sous-titres (.srt)"
        case .md: "Markdown (.md)"
        }
    }

    var fileExtension: String { rawValue }
}

enum OllamaModel: String, CaseIterable, Identifiable {
    case llama3_1 = "llama3.1:8b"
    case mistral = "mistral:latest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .llama3_1: "Llama 3.1 (8B)"
        case .mistral: "Mistral"
        }
    }
}
