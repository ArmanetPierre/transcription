import SwiftUI

/// Vue SwiftUI qui rend du Markdown avec titres, listes, paragraphes, etc.
/// Contrairement a `Text(AttributedString(markdown:))` qui ne gere que l'inline,
/// cette vue parse les blocs et applique les bons styles (taille des titres, puces, etc.)
struct MarkdownContentView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    // MARK: - Block Types

    private enum Block {
        case heading(level: Int, content: String)
        case paragraph(content: String)
        case unorderedListItem(content: String)
        case orderedListItem(number: Int, content: String)
        case separator
    }

    // MARK: - Parser

    private func parseBlocks() -> [Block] {
        var blocks: [Block] = []
        let lines = text.components(separatedBy: "\n")
        var paragraphLines: [String] = []

        func flushParagraph() {
            let joined = paragraphLines
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                blocks.append(.paragraph(content: joined))
            }
            paragraphLines = []
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Ligne vide = fin de paragraphe
            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            // Titres (### avant ## avant #)
            if trimmed.hasPrefix("#### ") {
                flushParagraph()
                blocks.append(.heading(level: 4, content: String(trimmed.dropFirst(5))))
                continue
            }
            if trimmed.hasPrefix("### ") {
                flushParagraph()
                blocks.append(.heading(level: 3, content: String(trimmed.dropFirst(4))))
                continue
            }
            if trimmed.hasPrefix("## ") {
                flushParagraph()
                blocks.append(.heading(level: 2, content: String(trimmed.dropFirst(3))))
                continue
            }
            if trimmed.hasPrefix("# ") {
                flushParagraph()
                blocks.append(.heading(level: 1, content: String(trimmed.dropFirst(2))))
                continue
            }

            // Liste non ordonnee
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                blocks.append(.unorderedListItem(content: String(trimmed.dropFirst(2))))
                continue
            }

            // Liste ordonnee: "1. contenu"
            if let (number, content) = parseOrderedListItem(trimmed) {
                flushParagraph()
                blocks.append(.orderedListItem(number: number, content: content))
                continue
            }

            // Separateur horizontal
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                blocks.append(.separator)
                continue
            }

            // Texte normal
            paragraphLines.append(trimmed)
        }

        flushParagraph()
        return blocks
    }

    private func parseOrderedListItem(_ line: String) -> (Int, String)? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let prefix = line[line.startIndex..<dotIndex]
        guard let number = Int(prefix), number > 0, number < 100 else { return nil }
        let afterDot = line[line.index(after: dotIndex)...]
        guard afterDot.hasPrefix(" ") else { return nil }
        let content = afterDot.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return nil }
        return (number, content)
    }

    // MARK: - Block Views

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let content):
            inlineMarkdown(content)
                .font(headingFont(level: level))
                .foregroundStyle(.primary)
                .padding(.top, level <= 2 ? 8 : 4)

        case .paragraph(let content):
            inlineMarkdown(content)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

        case .unorderedListItem(let content):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•")
                    .foregroundStyle(.tertiary)
                inlineMarkdown(content)
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            .padding(.leading, 16)

        case .orderedListItem(let number, let content):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(number).")
                    .foregroundStyle(.tertiary)
                    .frame(minWidth: 20, alignment: .trailing)
                inlineMarkdown(content)
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            .padding(.leading, 12)

        case .separator:
            Divider()
                .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: .title2.bold()
        case 2: .headline
        case 3: .subheadline.bold()
        default: .callout.bold()
        }
    }

    /// Rend les styles inline : **bold**, *italic*, etc. via AttributedString
    private func inlineMarkdown(_ text: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        }
        return Text(text)
    }
}
