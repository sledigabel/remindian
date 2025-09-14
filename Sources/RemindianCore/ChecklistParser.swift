import Foundation

public struct ChecklistItem: Equatable, CustomStringConvertible {
    public let rawLine: String
    public let text: String
    public let comment: String?
    public let lineNumber: Int

    public var description: String {
        if let comment { return "[line: \(lineNumber)] \(text) (comment: \(comment))" }
        return "[line: \(lineNumber)] \(text)"
    }
}

public struct ChecklistParser {
    // Pattern enforces:
    // - optional leading indentation
    // - hyphen, exactly one space, then [] or [x]/[X] (no spaces inside)
    // - exactly one space after ] before text
    // - capture text until optional Obsidian comment (%% ... %%) or line end
    // - optional trailing whitespace
    private static let pattern = "^[\\t ]*- \\[(?:[xX])?\\] ([^%\\n]*?)(?:[\\t ]*%%(.*?)%%)?[\\t ]*$"
    private static let regex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()

    public static func parseLines(_ content: String) -> [ChecklistItem] {
        var results: [ChecklistItem] = []
        let lines = content.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            guard let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) else { continue }
            guard match.numberOfRanges >= 2 else { continue }
            // Extract text (range 1)
            let textRange = match.range(at: 1)
            let commentRange = match.numberOfRanges > 2 ? match.range(at: 2) : .init(location: NSNotFound, length: 0)
            let text = substring(line, range: textRange).trimmingCharacters(in: .whitespacesAndNewlines)
            let comment = commentRange.location != NSNotFound ? substring(line, range: commentRange).trimmingCharacters(in: .whitespacesAndNewlines) : nil
            // Skip empty text just in case
            guard !text.isEmpty else { continue }
            results.append(ChecklistItem(rawLine: line, text: text, comment: comment, lineNumber: idx + 1))
        }
        return results
    }

    private static func substring(_ line: String, range: NSRange) -> String {
        guard range.location != NSNotFound, let swiftRange = Range(range, in: line) else { return "" }
        return String(line[swiftRange])
    }
}
