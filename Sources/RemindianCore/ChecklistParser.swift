import Foundation

public struct ChecklistItem: Equatable, CustomStringConvertible {
    public let rawLine: String
    public let checked: Bool
    public let title: String
    public let comment: String?
    public let lineNumber: Int
    public let list: String
    public var reminderId: String?
    public var reminderList: String?

    public var hasComment: Bool { comment != nil }

    // Backwards compatibility (tests previously referenced text)
    public var text: String { title }

    // Regular expression for identifying reminder IDs and lists in comments
    private static let reminderPattern = "([A-Z0-9-]+) -- ([^%]+)"
    private static let reminderRegex = try! NSRegularExpression(
        pattern: reminderPattern, options: [])

    // Simple method to create a copy of this item
    public func copy(withComment: String? = nil) -> ChecklistItem {
        return ChecklistItem(
            rawLine: rawLine,
            checked: checked,
            title: title,
            comment: withComment ?? comment,
            lineNumber: lineNumber,
            list: list,
            reminderId: reminderId,
            reminderList: reminderList
        )
    }
    
    public func parseReminderInfo() -> (reminderId: String?, reminderList: String?) {
        guard let comment = comment else {
            return (nil, nil)
        }
        
        if let match = ChecklistItem.reminderRegex.firstMatch(
            in: comment, options: [], range: NSRange(location: 0, length: comment.utf16.count)),
           match.numberOfRanges > 2
        {
            let idRange = match.range(at: 1)
            let listRange = match.range(at: 2)
            
            if let idSwiftRange = Range(idRange, in: comment),
               let listSwiftRange = Range(listRange, in: comment)
            {
                let reminderId = String(comment[idSwiftRange])
                let reminderList = String(comment[listSwiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                return (reminderId, reminderList)
            }
        }
        
        return (nil, nil)
    }
    
    public func withReminderInfo() -> ChecklistItem {
        let (reminderId, reminderList) = parseReminderInfo()
        return ChecklistItem(
            rawLine: rawLine,
            checked: checked,
            title: title,
            comment: comment,
            lineNumber: lineNumber,
            list: list,
            reminderId: reminderId,
            reminderList: reminderList
        )
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
    
    public func toStringWithReminderInfo(reminderId: String, reminderList: String) -> String {
        // Extract indentation from the original line
        let indentation = String(rawLine.prefix(while: { $0 == " " || $0 == "\t" }))
        let checkmark = checked ? "[x]" : "[ ]"
        
        return "\(indentation)- \(checkmark) \(title)  %% \(reminderId) -- \(reminderList) %%"
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
            let checked = checkedToken == "x" || checkedToken == "X"
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
                    lineNumber: idx + 1, list: list, reminderId: nil, reminderList: nil))
        }
        return results
    }

    private static func substring(_ line: String, range: NSRange) -> String {
        guard range.location != NSNotFound, let swiftRange = Range(range, in: line) else {
            return ""
        }
        return String(line[swiftRange])
    }

    public static func rewriteFile(at url: URL, outputURL: URL? = nil, reminderManager: RemindersManager? = nil) async throws -> URL {
        let content = try String(contentsOf: url)

        // Parse the content into ChecklistItems
        let allLines = content.components(separatedBy: .newlines)
        let items = parseLines(content)

        // Create a dictionary of line numbers to updated items
        var updatedItemsByLine: [Int: ChecklistItem] = [:]
        for item in items {
            let updatedItem = await updateReminder(item, reminderManager: reminderManager)
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

    public static func updateReminder(_ item: ChecklistItem, reminderManager: RemindersManager? = nil) async -> ChecklistItem {
        // Process reminders based on whether they have a reminder ID
        let manager = reminderManager ?? RemindersManager()
        
        // First, ensure we have access to the Reminders app
        guard await manager.requestAccess() else {
            print("Failed to get access to Reminders. Unable to sync.")
            return item // Return the original item unchanged
        }
        
        // Parse existing reminder info if any
        let (reminderId, reminderList) = item.parseReminderInfo()
        
        if let existingId = reminderId, let existingList = reminderList {
            // For existing reminders, check if the completion status in Apple Reminders
            // is different from the document's status
            let isCompletedInReminders = manager.isReminderCompleted(id: existingId)
            
            // Update the checked status to match Apple Reminders if they're different
            let updatedChecked = isCompletedInReminders
            
            // Only update the reminder in Apple if the document status has changed
            if updatedChecked != item.checked {
                _ = manager.updateReminder(id: existingId, title: item.title, isCompleted: updatedChecked)
            }
            
            if manager.getReminder(byId: existingId) == nil {
                print("Failed to retrieve reminder with ID: \(existingId)")
                // Return with the existing reminder info
                return ChecklistItem(
                    rawLine: item.rawLine,
                    checked: item.checked,
                    title: item.title,
                    comment: item.comment,
                    lineNumber: item.lineNumber,
                    list: item.list,
                    reminderId: reminderId,
                    reminderList: reminderList
                )
            }
            
            // Return the item with the updated checked status and the same reminder info
            return ChecklistItem(
                rawLine: item.rawLine,
                checked: updatedChecked, // Use the status from Apple Reminders
                title: item.title,
                comment: "\(existingId) -- \(existingList)", // Keep the existing ID and list
                lineNumber: item.lineNumber,
                list: item.list,
                reminderId: existingId,
                reminderList: existingList
            )
        } else {
            // This is a new reminder or one without proper reminder info
            // Create a new reminder in the Reminders app
            let listToUse = item.list // Use the list from the item
            
            if let newId = manager.createReminder(title: item.title, in: listToUse) {
                // Successfully created a new reminder
                // Return the item with the new reminder ID and list
                return ChecklistItem(
                    rawLine: item.rawLine,
                    checked: item.checked,
                    title: item.title,
                    comment: "\(newId) -- \(listToUse)", // Set the new ID and list
                    lineNumber: item.lineNumber,
                    list: item.list,
                    reminderId: newId,
                    reminderList: listToUse
                )
            } else {
                // Failed to create a new reminder
                print("Failed to create a new reminder")
                return item // Return the original item unchanged
            }
        }
    }
}
