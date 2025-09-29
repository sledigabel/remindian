import Foundation

public struct ChecklistItem: Equatable, CustomStringConvertible {
    public let rawLine: String
    public let checked: Bool
    public let title: String
    public let comment: String?
    public let lineNumber: Int
    public let list: String

    public var hasComment: Bool { comment != nil }

    // Backwards compatibility (tests previously referenced text)
    public var text: String { title }

    public var description: String {
        let status = checked ? "[x]" : "[ ]"
        if let comment {
            return "[\(list) | line: \(lineNumber)] \(status) \(title) (comment: \(comment))"
        }
        return "[\(list) | line: \(lineNumber)] \(status) \(title)"
    }
}

public struct ChecklistParser {
    // Pattern enforces:
    // - optional leading indentation
    // - hyphen, exactly one space, then [] or [x]/[X] capturing checked state
    // - exactly one space after ] before text
    // - capture text until optional Obsidian comment (%% ... %%) or line end
    // - optional spaces/tabs before the opening %%
    // - optional trailing whitespace
    private static let pattern = "^[\\t ]*- \\[([xX]?)\\] ([^%\\n]*?)(?:[\\t ]*%%(.*?)%%)?[\\t ]*$"
    private static let regex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()

    public static func parseLines(_ content: String, list: String = "remindian") -> [ChecklistItem]
    {
        var results: [ChecklistItem] = []
        let lines = content.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            guard
                let match = regex.firstMatch(
                    in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
            else { continue }
            guard match.numberOfRanges >= 3 else { continue }
            let checkedRange = match.range(at: 1)
            let titleRange = match.range(at: 2)
            let commentRange =
                match.numberOfRanges > 3
                ? match.range(at: 3) : .init(location: NSNotFound, length: 0)

            let checkedToken = substring(line, range: checkedRange)
            let checked = !checkedToken.isEmpty
            let title = substring(line, range: titleRange).trimmingCharacters(
                in: .whitespacesAndNewlines)
            let comment =
                commentRange.location != NSNotFound
                ? substring(line, range: commentRange).trimmingCharacters(
                    in: .whitespacesAndNewlines) : nil
            guard !title.isEmpty else { continue }
            results.append(
                ChecklistItem(
                    rawLine: line, checked: checked, title: title, comment: comment,
                    lineNumber: idx + 1, list: list))
        }
        return results
    }

    private static func substring(_ line: String, range: NSRange) -> String {
        guard range.location != NSNotFound, let swiftRange = Range(range, in: line) else {
            return ""
        }
        return String(line[swiftRange])
    }
}
