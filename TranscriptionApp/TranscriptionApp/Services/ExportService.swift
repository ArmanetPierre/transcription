import Foundation

struct ExportService {
    static func export(project: TranscriptionProject, format: ExportFormat) -> String {
        switch format {
        case .txt: exportTXT(project: project)
        case .json: exportJSON(project: project)
        case .srt: exportSRT(project: project)
        case .md: exportMD(project: project)
        }
    }

    // MARK: - TXT

    static func exportTXT(project: TranscriptionProject) -> String {
        var result = ""

        // Compte rendu en tete
        if let report = project.meetingReport, !report.isEmpty {
            result += "=== COMPTE RENDU DE REUNION ===\n\n"
            result += report + "\n\n"
            result += "=== TRANSCRIPTION ===\n\n"
        }

        result += project.sortedSegments.map { seg in
            let speaker = project.displayName(for: seg.speakerLabel ?? "Inconnu")
            let start = TimeFormatting.timestamp(seg.startTime)
            let end = TimeFormatting.timestamp(seg.endTime)
            return "[\(start) - \(end)] \(speaker) : \(seg.text)"
        }.joined(separator: "\n")

        return result
    }

    // MARK: - JSON

    static func exportJSON(project: TranscriptionProject) -> String {
        let segments = project.sortedSegments.map { seg -> [String: Any] in
            var dict: [String: Any] = [
                "id": seg.index,
                "start": seg.startTime,
                "end": seg.endTime,
                "text": seg.text,
            ]
            if let label = seg.speakerLabel {
                dict["speaker"] = project.displayName(for: label)
            }
            return dict
        }

        var root: [String: Any] = ["segments": segments]

        // Compte rendu
        if let report = project.meetingReport, !report.isEmpty {
            root["meetingReport"] = report
        }

        // Syntheses par speaker
        let summaries = project.speakerSummaries
        if !summaries.isEmpty {
            let mapped = summaries.map { key, value in
                [project.displayName(for: key): value]
            }.reduce(into: [String: String]()) { result, dict in
                result.merge(dict) { _, new in new }
            }
            root["speakerSummaries"] = mapped
        }

        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    // MARK: - SRT

    static func exportSRT(project: TranscriptionProject) -> String {
        project.sortedSegments.enumerated().map { i, seg in
            let speaker = project.displayName(for: seg.speakerLabel ?? "Inconnu")
            let start = TimeFormatting.srtTimestamp(seg.startTime)
            let end = TimeFormatting.srtTimestamp(seg.endTime)
            return "\(i + 1)\n\(start) --> \(end)\n[\(speaker)] \(seg.text)\n"
        }.joined(separator: "\n")
    }

    // MARK: - Markdown

    static func exportMD(project: TranscriptionProject) -> String {
        var result = "# \(project.title)\n\n"

        // Compte rendu en tete
        if let report = project.meetingReport, !report.isEmpty {
            result += "## Compte Rendu\n\n"
            result += report + "\n\n---\n\n"
        }

        // Syntheses par speaker
        let summaries = project.speakerSummaries
        if !summaries.isEmpty {
            result += "## Syntheses par Speaker\n\n"
            for speaker in project.uniqueSpeakers {
                if let summary = summaries[speaker] {
                    let name = project.displayName(for: speaker)
                    result += "### \(name)\n\n\(summary)\n\n"
                }
            }
            result += "---\n\n"
        }

        // Transcription
        result += "## Transcription\n\n"

        var currentSpeaker: String?
        var currentTexts: [String] = []
        var currentStart: Double = 0

        for seg in project.sortedSegments {
            let speaker = seg.speakerLabel ?? "Inconnu"
            if speaker != currentSpeaker {
                if let prev = currentSpeaker {
                    let name = project.displayName(for: prev)
                    let ts = TimeFormatting.timestamp(currentStart)
                    result += "**\(name)** _\(ts)_\n\n"
                    result += currentTexts.joined(separator: " ") + "\n\n"
                }
                currentSpeaker = speaker
                currentTexts = [seg.text]
                currentStart = seg.startTime
            } else {
                currentTexts.append(seg.text)
            }
        }

        if let last = currentSpeaker {
            let name = project.displayName(for: last)
            let ts = TimeFormatting.timestamp(currentStart)
            result += "**\(name)** _\(ts)_\n\n"
            result += currentTexts.joined(separator: " ") + "\n\n"
        }

        return result
    }
}
