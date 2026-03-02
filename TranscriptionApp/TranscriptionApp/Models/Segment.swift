import Foundation
import SwiftData

@Model
final class Segment {
    var id: UUID = UUID()
    var index: Int = 0
    var startTime: Double = 0
    var endTime: Double = 0
    var text: String = ""
    var originalText: String = ""
    var speakerLabel: String?
    var avgLogprob: Double?
    var noSpeechProb: Double?
    var project: TranscriptionProject?

    init() {}

    var duration: Double {
        endTime - startTime
    }

    static func create(from result: ResultSegment, project: TranscriptionProject) -> Segment {
        let segment = Segment()
        segment.index = result.id
        segment.startTime = result.start
        segment.endTime = result.end
        segment.text = result.text
        segment.originalText = result.text
        segment.speakerLabel = result.speaker
        segment.avgLogprob = result.avgLogprob
        segment.noSpeechProb = result.noSpeechProb
        segment.project = project
        return segment
    }
}
