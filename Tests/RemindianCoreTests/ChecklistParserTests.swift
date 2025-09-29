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
    
    func testCustomListName() {
        let input = "- [] task in custom list"
        let listName = "work-H2-2025"
        let items = ChecklistParser.parseLines(input, list: listName)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.list, listName)
    }
    
    // MARK: - File Rewriting Tests
    
    func testRewriteAddsComments() throws {
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
        
        // Rewrite the file in place
        let rewrittenFile = try ChecklistParser.rewriteFile(at: sourceFile)
        
        // Read the rewritten file
        let rewrittenContent = try String(contentsOf: rewrittenFile)
        
        // Verify comments were added
        XCTAssertTrue(rewrittenContent.contains("- [] Task without comment  %% COMMENT 1 %%"))
        XCTAssertTrue(rewrittenContent.contains("- [x] Another task  %% COMMENT 1 %%"))
        
        // Verify unrelated content is preserved
        XCTAssertTrue(rewrittenContent.contains("# Test File"))
        XCTAssertTrue(rewrittenContent.contains("Some text"))
        XCTAssertTrue(rewrittenContent.contains("More text"))
    }
    
    func testRewriteIncrementsCommentNumbers() throws {
        // Create a test file with existing comments
        let content = """
        # Test File
        - [] Task with comment  %% COMMENT 1 %%
        - [x] Another task with comment  %% COMMENT 3 %%
        - [] Task with other comment  %% Other comment %%
        """
        
        let sourceFile = tempDir.appendingPathComponent("with_comments.md")
        try content.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Rewrite the file in place
        let rewrittenFile = try ChecklistParser.rewriteFile(at: sourceFile)
        
        // Read the rewritten file
        let rewrittenContent = try String(contentsOf: rewrittenFile)
        
        // Verify comment numbers were incremented
        XCTAssertTrue(rewrittenContent.contains("- [] Task with comment  %% COMMENT 2 %%"))
        XCTAssertTrue(rewrittenContent.contains("- [x] Another task with comment  %% COMMENT 4 %%"))
        
        // Verify other comments are replaced with COMMENT 1
        XCTAssertTrue(rewrittenContent.contains("- [] Task with other comment  %% COMMENT 1 %%"))
    }
    
    func testRewriteToOutputFile() throws {
        // Create a test file
        let content = """
        # Test File
        - [] Task without comment
        """
        
        let sourceFile = tempDir.appendingPathComponent("source.md")
        let outputFile = tempDir.appendingPathComponent("output.md")
        try content.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Rewrite the file to output
        let rewrittenFile = try ChecklistParser.rewriteFile(at: sourceFile, outputURL: outputFile)
        
        // Check that the output file was created and is different from the source
        XCTAssertEqual(rewrittenFile.path, outputFile.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        
        // The source file should be unchanged
        let sourceContent = try String(contentsOf: sourceFile)
        XCTAssertEqual(sourceContent, content)
        
        // Output file should have comments
        let outputContent = try String(contentsOf: outputFile)
        XCTAssertTrue(outputContent.contains("- [] Task without comment  %% COMMENT 1 %%"))
    }
}
