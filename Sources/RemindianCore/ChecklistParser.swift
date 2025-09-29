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
    
    // Regular expression for identifying comment numbers
    private static let commentNumberPattern = "COMMENT (\\d+)"
    private static let commentNumberRegex = try! NSRegularExpression(pattern: commentNumberPattern, options: [])
    
    public func updateComment() -> ChecklistItem {
        let newComment = ChecklistItem.incrementCommentNumber(comment)
        return ChecklistItem(
            rawLine: rawLine, 
            checked: checked, 
            title: title, 
            comment: newComment, 
            lineNumber: lineNumber, 
            list: list
        )
    }
    
    private static func incrementCommentNumber(_ comment: String?) -> String {
        guard let comment = comment else {
            return "COMMENT 1"
        }
        
        if let match = commentNumberRegex.firstMatch(
            in: comment, options: [], range: NSRange(location: 0, length: comment.utf16.count)),
           match.numberOfRanges > 1 {
            let numberRange = match.range(at: 1)
            if let swiftRange = Range(numberRange, in: comment),
               let number = Int(comment[swiftRange]) {
                let nextNumber = number + 1
                return "COMMENT \(nextNumber)"
            }
        }
        
        // If no number pattern found or can't parse number, default to "COMMENT 1"
        return "COMMENT 1"
    }
    
    public var description: String {
        let status = checked ? "[x]" : "[ ]"
        if let comment {
            return "[\(list) | line: \(lineNumber)] \(status) \(title) (comment: \(comment))"
        }
        return "[\(list) | line: \(lineNumber)] \(status) \(title)"
    }
    
    public func toString() -> String {
        // Extract indentation from the original line
        let indentation = String(rawLine.prefix(while: { $0 == " " || $0 == "\t" }))
        let checkmark = checked ? "[x]" : "[ ]"
        
        if let comment = comment {
            return "\(indentation)- \(checkmark) \(title)  %% \(comment) %%"
        } else {
            return "\(indentation)- \(checkmark) \(title)"
        }
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
    // - Note: We allow for a space inside the brackets to handle formatted output
    private static let pattern = "^[\\t ]*- \\[([xX ]?)\\] ([^%\\n]*?)(?:[\\t ]*%%(.*?)%%)?[\\t ]*$"
    private static let regex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()
    
    // No longer need the comment number regex here as it's moved to ChecklistItem

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
        
        // Parse the content into ChecklistItems
        let allLines = content.components(separatedBy: .newlines)
        let items = parseLines(content)
        
        // Create a dictionary of line numbers to updated items
        var updatedItemsByLine: [Int: ChecklistItem] = [:]
        for item in items {
            let updatedItem = updateReminder(item)
            updatedItemsByLine[updatedItem.lineNumber] = updatedItem
        }
        
        // Rewrite each line, using the updated item if it exists
        var rewrittenLines = [String]()
        for (index, line) in allLines.enumerated() {
            let lineNumber = index + 1
            if let updatedItem = updatedItemsByLine[lineNumber] {
                rewrittenLines.append(updatedItem.toString())
            } else {
                rewrittenLines.append(line)
            }
        }
        
        let rewrittenContent = rewrittenLines.joined(separator: "\n")
        let destinationURL = outputURL ?? url
        try rewrittenContent.write(to: destinationURL, atomically: true, encoding: .utf8)
        
        return destinationURL
    }
    
    public static func updateReminder(_ item: ChecklistItem) -> ChecklistItem {
        return item.updateComment()
    }
}
