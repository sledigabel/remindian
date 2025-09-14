import XCTest
@testable import RemindianCore

class ChecklistParserTests: XCTestCase {
    func testParsesSimpleLine() {
        let input = "- [] this is a reminder"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.text, "this is a reminder")
        XCTAssertNil(items.first?.comment)
    }

    func testParsesCheckedLineLowercase() {
        let input = "- [x] completed task"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.text, "completed task")
    }

    func testParsesCheckedLineUppercase() {
        let input = "- [X] done task"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.text, "done task")
    }

    func testParsesIndentedLine() {
        let input = "\t   - [] another reminder"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.text, "another reminder")
    }

    func testParsesLineWithComment() {
        let input = "- [] do something  %% created on 2025-09-14 %%"
        let items = ChecklistParser.parseLines(input)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.text, "do something")
        XCTAssertEqual(items.first?.comment, "created on 2025-09-14")
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
        XCTAssertEqual(items.map { $0.text }, ["good one", "spaced okay", "another"])
        XCTAssertEqual(items.last?.comment, "meta")
    }

    func testFixtureMixed1() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "mixed1", withExtension: "md"))
        let text = try String(contentsOf: url)
        let items = ChecklistParser.parseLines(text)
        XCTAssertEqual(items.map { $0.text }, ["first reminder", "second reminder", "third reminder"])
        XCTAssertEqual(items.first?.comment, "created 2025-09-14")
    }

    func testFixtureMixed2() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "mixed2", withExtension: "md"))
        let text = try String(contentsOf: url)
        let items = ChecklistParser.parseLines(text)
        XCTAssertEqual(items.map { $0.text }, ["indented task one", "task two", "trailing spaces", "final valid"])
        XCTAssertEqual(items[1].comment, "meta")
        XCTAssertEqual(items[2].comment, "comment with spaces")
    }
}
