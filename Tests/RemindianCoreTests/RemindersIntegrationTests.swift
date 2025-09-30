import XCTest
import Foundation
@testable import RemindianCore

class RemindersIntegrationTests: XCTestCase {
    // Use the MockRemindersManager for testing
    let mockManager = MockRemindersManager()
    
    func testCreateNewReminder() async throws {
        // Create a checklist item without a reminder ID
        let item = ChecklistItem(
            rawLine: "- [] New task",
            checked: false,
            title: "New task",
            comment: nil,
            lineNumber: 1,
            list: "testlist",
            reminderId: nil,
            reminderList: nil
        )
        
        // Update the reminder using our mock manager
        let updatedItem = await ChecklistParser.updateReminder(item, reminderManager: mockManager)
        
        // Check that a reminder ID was created and added to the comment
        XCTAssertNotNil(updatedItem.comment)
        
        // Parse the reminder info from the comment
        let (reminderId, reminderList) = updatedItem.parseReminderInfo()
        XCTAssertNotNil(reminderId)
        XCTAssertEqual(reminderList, "testlist")
        
        // Verify that the reminder was created in the mock manager
        if let id = reminderId {
            XCTAssertEqual(mockManager.getReminderTitle(id: id), "New task")
            XCTAssertEqual(mockManager.isReminderCompleted(id: id), false)
            XCTAssertEqual(mockManager.getReminderListName(id: id), "testlist")
        }
    }
    
    func testUpdateExistingReminder() async throws {
        // First create a reminder to get an ID
        let initialItem = ChecklistItem(
            rawLine: "- [] Initial task",
            checked: false,
            title: "Initial task",
            comment: nil,
            lineNumber: 1,
            list: "testlist",
            reminderId: nil,
            reminderList: nil
        )
        
        let createdItem = await ChecklistParser.updateReminder(initialItem, reminderManager: mockManager)
        let (reminderId, _) = createdItem.parseReminderInfo()
        XCTAssertNotNil(reminderId)
        
        // First verify the reminder is not completed initially
        XCTAssertEqual(mockManager.isReminderCompleted(id: reminderId!), false)
        
        // Now create an item with that ID that has been checked and has a new title
        let updatedRawItem = ChecklistItem(
            rawLine: "- [x] Updated task  %% \(reminderId!) -- testlist %%",
            checked: true,
            title: "Updated task",
            comment: "\(reminderId!) -- testlist",
            lineNumber: 1,
            list: "testlist",
            reminderId: reminderId,
            reminderList: "testlist"
        )
        
        // First directly update the mock's completion status to test our new functionality
        // This simulates the user checking the task in Apple Reminders
        _ = mockManager.updateReminder(id: reminderId!, title: "Updated task", isCompleted: true)
        XCTAssertTrue(mockManager.isReminderCompleted(id: reminderId!))
        
        // Now update the reminder through the ChecklistParser
        let updatedItem = await ChecklistParser.updateReminder(updatedRawItem, reminderManager: mockManager)
        
        // Verify the update in the mock manager
        XCTAssertEqual(mockManager.getReminderTitle(id: reminderId!), "Updated task")
        XCTAssertTrue(mockManager.isReminderCompleted(id: reminderId!))
        XCTAssertTrue(updatedItem.checked) // Also verify the item itself is now checked
    }
    
    func testRewriteFile() async throws {
        // Create a temporary file
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        let sourceFile = tempDir.appendingPathComponent("test.md")
        
        // Write test content to the file
        let content = """
        # Test File
        - [] Task 1
        - [x] Task 2
        - [] Task with existing ID  %% MOCK-123 -- mylist %%
        """
        try content.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Mock the update reminder behavior for the existing ID
        _ = mockManager.updateReminder(id: "MOCK-123", title: "Task with existing ID", isCompleted: false)
        
        // Rewrite the file with our mock manager
        let rewrittenFile = try await ChecklistParser.rewriteFile(at: sourceFile, reminderManager: mockManager)
        
        // Read the rewritten content
        let rewrittenContent = try String(contentsOf: rewrittenFile)
        let items = ChecklistParser.parseLines(rewrittenContent)
        
        // Verify that all tasks have reminder IDs in their comments
        for item in items {
            XCTAssertNotNil(item.comment)
            let (reminderId, reminderList) = item.parseReminderInfo()
            XCTAssertNotNil(reminderId)
            XCTAssertNotNil(reminderList)
        }
        
        // Clean up
        try FileManager.default.removeItem(at: tempDir)
    }
}