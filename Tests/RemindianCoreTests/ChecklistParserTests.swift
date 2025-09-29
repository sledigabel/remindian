import XCTest
@testable import RemindianCore

class ChecklistParserTests: XCTestCase {
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
}
