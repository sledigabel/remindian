import XCTest
import Foundation
@testable import RemindianCore

class ChecklistParserTests: XCTestCase {
    // Temporary directory for file operations during tests
    var tempDir: URL!
    
    override func setUp() {
        super.setUp()
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }
    func testParsesSimpleLine() {
        let input = "- [] this is a reminder"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "this is a reminder")
        XCTAssertFalse(items.first!.checked)
        XCTAssertFalse(items.first!.hasComment)
        XCTAssertNil(items.first?.comment)
        XCTAssertEqual(items.first?.list, "remindian")  // Default list name
    }

    func testParsesCheckedLineLowercase() {
        let input = "- [x] completed task"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "completed task")
        XCTAssertTrue(items.first!.checked)
    }

    func testParsesCheckedLineUppercase() {
        let input = "- [X] done task"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "done task")
        XCTAssertTrue(items.first!.checked)
    }

    func testParsesIndentedLine() {
        let input = "\t   - [] another reminder"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "another reminder")
        XCTAssertFalse(items.first!.checked)
    }

    func testParsesLineWithComment() {
        let input = "- [] do something  %% created on 2025-09-14 %%"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "do something")
        XCTAssertEqual(items.first?.comment, "created on 2025-09-14")
        XCTAssertTrue(items.first!.hasComment)
    }

    func testIgnoresInvalidSpacingInsidePrefix() {
        let input = "-   [] bad spacing"
        let items = ChecklistParser.parseLines(input)
        XCTAssertTrue(items.isEmpty)
    }

    func testMultipleLinesMixedInline() {
        let input = """
- [] good one
-   [] bad
   - [] spaced okay
- [] another %% meta %%
"""
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.map { $0.title }, ["good one", "spaced okay", "another"])
        XCTAssertEqual(items.last?.comment, "meta")
    }

    func testFixtureMixed1() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "mixed1", withExtension: "md"))
        let text = try String(contentsOf: url)
        let items = ChecklistParser.parseLines(text)
        XCTAssertEqual(items.map { $0.title }, ["first reminder", "second reminder", "third reminder"])
        XCTAssertEqual(items.first?.comment, "created 2025-09-14")
        XCTAssertTrue(items.first!.checked)
        XCTAssertFalse(items[1].checked)
        XCTAssertTrue(items[2].checked)
    }

    func testFixtureMixed2() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "mixed2", withExtension: "md"))
        let text = try String(contentsOf: url)
        let items = ChecklistParser.parseLines(text)
        XCTAssertEqual(items.map { $0.title }, ["indented task one", "task two", "trailing spaces", "final valid"])
        XCTAssertTrue(items[0].checked)
        XCTAssertFalse(items[1].checked)
        XCTAssertTrue(items[2].checked)
        XCTAssertTrue(items[3].checked)
        XCTAssertEqual(items[1].comment, "meta")
        XCTAssertEqual(items[2].comment, "comment with spaces")
    }

    func testUnclosedCommentNotMatched() {
        let input = "- [] bad line %% unclosed comment"
        let items = ChecklistParser.parseLines(input)
        XCTAssertTrue(items.isEmpty)
    }
    
    func testParseReminderInfo() {
        // Test with reminder ID and list in the comment
        let item1 = ChecklistItem(
            rawLine: "- [] Task with reminder  %% ABC123-XYZ -- Personal Tasks %%",
            checked: false,
            title: "Task with reminder",
            comment: "ABC123-XYZ -- Personal Tasks",
            lineNumber: 1,
            list: "test",
            reminderId: nil,
            reminderList: nil
        )
        
        let (id1, list1) = item1.parseReminderInfo()
        XCTAssertEqual(id1, "ABC123-XYZ")
        XCTAssertEqual(list1, "Personal Tasks")
        
        // Test with non-matching comment
        let item2 = ChecklistItem(
            rawLine: "- [] Task with other comment  %% Some comment %%",
            checked: false,
            title: "Task with other comment",
            comment: "Some comment",
            lineNumber: 2,
            list: "test",
            reminderId: nil,
            reminderList: nil
        )
        
        let (id2, list2) = item2.parseReminderInfo()
        XCTAssertNil(id2)
        XCTAssertNil(list2)
        
        // Test with no comment
        let item3 = ChecklistItem(
            rawLine: "- [] Task with no comment",
            checked: false,
            title: "Task with no comment",
            comment: nil,
            lineNumber: 3,
            list: "test",
            reminderId: nil,
            reminderList: nil
        )
        
        let (id3, list3) = item3.parseReminderInfo()
        XCTAssertNil(id3)
        XCTAssertNil(list3)
        
        // Test withReminderInfo method
        let updatedItem = item1.withReminderInfo()
        XCTAssertEqual(updatedItem.reminderId, "ABC123-XYZ")
        XCTAssertEqual(updatedItem.reminderList, "Personal Tasks")
    }
    
    func testToStringWithReminderInfo() {
        // Test with unchecked item
        let item1 = ChecklistItem(
            rawLine: "- [] Task with reminder",
            checked: false,
            title: "Task with reminder",
            comment: nil,
            lineNumber: 1,
            list: "test",
            reminderId: nil,
            reminderList: nil
        )
        
        let result1 = item1.toStringWithReminderInfo(reminderId: "ABC123", reminderList: "Personal")
        XCTAssertEqual(result1, "- [ ] Task with reminder  %% ABC123 -- Personal %%")
        
        // Test with checked item
        let item2 = ChecklistItem(
            rawLine: "    - [x] Indented task",
            checked: true,
            title: "Indented task",
            comment: "Some comment",
            lineNumber: 2,
            list: "test",
            reminderId: nil,
            reminderList: nil
        )
        
        let result2 = item2.toStringWithReminderInfo(reminderId: "XYZ-789", reminderList: "Work")
        XCTAssertEqual(result2, "    - [x] Indented task  %% XYZ-789 -- Work %%")
    }
    
    func testCustomListName() {
        let input = "- [] task in custom list"
        let listName = "work-H2-2025"
        let items = ChecklistParser.parseLines(input, list: listName)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.list, listName)
    }
    
    // MARK: - File Rewriting Tests
    
    func testRewriteAddsComments() async throws {
        // Create a test file with no comments
        let content = """
        # Test File
        Some text
        - [] Task without comment
        - [x] Another task
        More text
        """
        
        let sourceFile = tempDir.appendingPathComponent("no_comments.md")
        try content.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Create a mock manager that will be used for testing
        let mockManager = MockRemindersManager()
        
        // Rewrite the file in place using the mock manager
        let rewrittenFile = try await ChecklistParser.rewriteFile(at: sourceFile, reminderManager: mockManager)
        
        // Read the rewritten file
        let rewrittenContent = try String(contentsOf: rewrittenFile)
        
        // Parse the content to get the reminder IDs
        let items = ChecklistParser.parseLines(rewrittenContent)
        XCTAssertEqual(items.count, 2)
        
        // Verify all items have comments with reminder IDs
        for item in items {
            XCTAssertNotNil(item.comment)
            let (reminderId, reminderList) = item.parseReminderInfo()
            XCTAssertNotNil(reminderId)
            XCTAssertNotNil(reminderList)
        }
        
        // Verify unrelated content is preserved
        XCTAssertTrue(rewrittenContent.contains("# Test File"))
        XCTAssertTrue(rewrittenContent.contains("Some text"))
        XCTAssertTrue(rewrittenContent.contains("More text"))
    }
    
    func testRewriteHandlesExistingComments() async throws {
        // Create a test file with existing reminder IDs and other comments
        let content = """
        # Test File
        - [] Task with reminder ID  %% MOCK-ABC123 -- testlist %%
        - [x] Another task with comment  %% COMMENT 3 %%
        - [] Task with other comment  %% Other comment %%
        """
        
        let sourceFile = tempDir.appendingPathComponent("with_comments.md")
        try content.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Create a mock manager
        let mockManager = MockRemindersManager()
        
        // Pre-configure the mock manager to recognize the existing ID
        _ = mockManager.updateReminder(id: "MOCK-ABC123", title: "Task with reminder ID", isCompleted: false)
        
        // Rewrite the file in place
        let rewrittenFile = try await ChecklistParser.rewriteFile(at: sourceFile, reminderManager: mockManager)
        
        // Read the rewritten file
        let rewrittenContent = try String(contentsOf: rewrittenFile)
        
        // Parse the rewritten content
        let items = ChecklistParser.parseLines(rewrittenContent)
        XCTAssertEqual(items.count, 3)
        
        // Verify all items have reminder IDs in their comments
        for item in items {
            XCTAssertNotNil(item.comment)
            let (reminderId, reminderList) = item.parseReminderInfo()
            XCTAssertNotNil(reminderId)
            XCTAssertNotNil(reminderList)
        }
        
        // Verify the first item still has its original ID
        XCTAssertTrue(rewrittenContent.contains("MOCK-ABC123"))
    }
    
    func testRewriteToOutputFile() async throws {
        // Create a test file
        let content = """
        # Test File
        - [] Task without comment
        """
        
        let sourceFile = tempDir.appendingPathComponent("source.md")
        let outputFile = tempDir.appendingPathComponent("output.md")
        try content.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Create a mock manager
        let mockManager = MockRemindersManager()
        
        // Rewrite the file to output
        let rewrittenFile = try await ChecklistParser.rewriteFile(at: sourceFile, outputURL: outputFile, reminderManager: mockManager)
        
        // Check that the output file was created and is different from the source
        XCTAssertEqual(rewrittenFile.path, outputFile.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        
        // The source file should be unchanged
        let sourceContent = try String(contentsOf: sourceFile)
        XCTAssertEqual(sourceContent, content)
        
        // Output file should have comments with reminder IDs
        let outputContent = try String(contentsOf: outputFile)
        let items = ChecklistParser.parseLines(outputContent)
        XCTAssertEqual(items.count, 1)
        
        // Verify the item has a reminder ID
        let (reminderId, reminderList) = items[0].parseReminderInfo()
        XCTAssertNotNil(reminderId)
        XCTAssertNotNil(reminderList)
    }
    
    func testSyncCompletionStatusFromReminders() async throws {
        // Create a test file with an unchecked task
        let content = """
        # Test File
        - [] Task that will be completed in Reminders  %% MOCK-ABC123 -- testlist %%
        """
        
        let sourceFile = tempDir.appendingPathComponent("completion_sync_test.md")
        try content.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Create a mock manager
        let mockManager = MockRemindersManager()
        
        // Make sure the reminder exists in our mock system first
        let listName = "testlist"
        if mockManager.reminderLists[listName] == nil {
            mockManager.reminderLists[listName] = [:]
        }
        mockManager.reminderLists[listName]?["MOCK-ABC123"] = "Task that will be completed in Reminders"
        
        // Set up the mock to recognize the existing ID and mark it as completed
        _ = mockManager.updateReminder(id: "MOCK-ABC123", title: "Task that will be completed in Reminders", isCompleted: true)
        
        // Verify the mock shows the reminder as completed
        XCTAssertTrue(mockManager.isReminderCompleted(id: "MOCK-ABC123"))
        
        // Rewrite the file, which should sync the completion status
        let rewrittenFile = try await ChecklistParser.rewriteFile(at: sourceFile, reminderManager: mockManager)
        
        // Read the rewritten content
        let rewrittenContent = try String(contentsOf: rewrittenFile)
        
        // Parse the rewritten content
        let items = ChecklistParser.parseLines(rewrittenContent)
        XCTAssertEqual(items.count, 1)
        
        // Verify the task is now checked in the document
        XCTAssertTrue(items[0].checked)
        XCTAssertTrue(rewrittenContent.contains("[x]"))
    }
    
    func testCopyMethod() {
        // Test the copy method
        
        // Test with no comment
        let item1 = ChecklistItem(
            rawLine: "- [] Task without comment",
            checked: false,
            title: "Task without comment",
            comment: nil,
            lineNumber: 1,
            list: "test",
            reminderId: nil,
            reminderList: nil
        )
        let copied1 = item1.copy()
        XCTAssertEqual(copied1.comment, nil)
        XCTAssertEqual(copied1.toString(), "- [ ] Task without comment")
        
        // Test with a comment
        let item2 = ChecklistItem(
            rawLine: "- [x] Task with comment  %% ABC123 -- Personal %%",
            checked: true,
            title: "Task with comment",
            comment: "ABC123 -- Personal",
            lineNumber: 2,
            list: "test",
            reminderId: "ABC123",
            reminderList: "Personal"
        )
        let copied2 = item2.copy()
        XCTAssertEqual(copied2.comment, "ABC123 -- Personal")
        XCTAssertEqual(copied2.toString(), "- [x] Task with comment  %% ABC123 -- Personal %%")
        
        // Test with a new comment
        let copied3 = item2.copy(withComment: "XYZ789 -- Work")
        XCTAssertEqual(copied3.comment, "XYZ789 -- Work")
        XCTAssertEqual(copied3.toString(), "- [x] Task with comment  %% XYZ789 -- Work %%")
    }
}
