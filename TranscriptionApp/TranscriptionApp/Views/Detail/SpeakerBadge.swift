import SwiftUI

struct SpeakerBadge: View {
    let name: String
    let label: String
    let onTap: () -> Void

    var body: some View {
        Text(name)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(SpeakerColors.color(for: label))
            )
            .onTapGesture { onTap() }
            .help("Click to rename")
    }
}
