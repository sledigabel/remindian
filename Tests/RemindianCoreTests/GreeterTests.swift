#if canImport(XCTest)
import XCTest
@testable import RemindianCore

final class GreeterTests: XCTestCase {
    func testHelloDefault() {
        XCTAssertEqual(Greeter.hello(), "Hello, world!")
    }

    func testHelloCustomName() {
        XCTAssertEqual(Greeter.hello(name: "Alice"), "Hello, Alice!")
    }
}
#endif
