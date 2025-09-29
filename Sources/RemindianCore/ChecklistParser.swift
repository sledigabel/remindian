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
    
    // Regex pattern to extract comment number
    private static let commentNumberPattern = "COMMENT (\\d+)"
    private static let commentNumberRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: commentNumberPattern, options: [])
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
    
    public static func rewriteFile(at url: URL, outputURL: URL? = nil) throws -> URL {
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)
        var rewrittenLines = [String]()
        
        for line in lines {
            if let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                let rewrittenLine = rewriteReminderLine(line: line, match: match)
                rewrittenLines.append(rewrittenLine)
            } else {
                rewrittenLines.append(line)
            }
        }
        
        let rewrittenContent = rewrittenLines.joined(separator: "\n")
        let destinationURL = outputURL ?? url
        try rewrittenContent.write(to: destinationURL, atomically: true, encoding: .utf8)
        
        return destinationURL
    }
    
    private static func rewriteReminderLine(line: String, match: NSTextCheckingResult) -> String {
        guard match.numberOfRanges >= 3 else { return line }
        
        let titleRange = match.range(at: 2)
        let commentRange = match.numberOfRanges > 3 ? match.range(at: 3) : .init(location: NSNotFound, length: 0)
        
        if commentRange.location == NSNotFound {
            // No comment found, add "COMMENT 1"
            return line.prefix(upTo: (line.utf16.count > titleRange.location + titleRange.length) ? String.Index(utf16Offset: titleRange.location + titleRange.length, in: line) : line.endIndex) + "  %% COMMENT 1 %%"
        } else {
            // Comment found, increment number
            let comment = substring(line, range: commentRange)
            let updatedComment = updateCommentNumber(comment)
            
            // Rebuild the line with the updated comment
            var lineComponents = [String]()
            
            // Add everything before the comment
            if let commentStartIndex = line.range(of: "%%", options: .literal)?.lowerBound {
                lineComponents.append(String(line.prefix(upTo: commentStartIndex)))
            }
            
            // Add the updated comment
            lineComponents.append("%% \(updatedComment) %%")
            
            return lineComponents.joined()
        }
    }
    
    private static func updateCommentNumber(_ comment: String) -> String {
        if let match = commentNumberRegex.firstMatch(in: comment, options: [], range: NSRange(location: 0, length: comment.utf16.count)),
           match.numberOfRanges > 1 {
            let numberRange = match.range(at: 1)
            if let number = Int(substring(comment, range: numberRange)) {
                let nextNumber = number + 1
                return "COMMENT \(nextNumber)"
            }
        }
        
        // If no number pattern found or can't parse number, add "COMMENT 1"
        return "COMMENT 1"
    }
}
