import SwiftUI

enum SpeakerColors {
    private static let palette: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .pink,
        .teal,
        .indigo,
        .mint,
        .brown,
        .cyan,
    ]

    /// Couleur deterministe pour un label de speaker
    static func color(for speakerLabel: String) -> Color {
        let hash = abs(speakerLabel.hashValue)
        return palette[hash % palette.count]
    }
}
