
import XCTest

class ComposedErrorTests: XCTestCase {

    func test_empty_initializer() {
        let error = Composed.Error()
        XCTAssertEqual(error.code, -1)
        XCTAssertEqual(error.text, "Undefined Error")
    }

    func test_initialized_properties() {
        let error = Composed.Error(code: 10, text: "two")
        XCTAssertEqual(error.code, 10)
        XCTAssertEqual(error.text, "two")
    }

    func test_string_convertible() {
        let error = Composed.Error()
        XCTAssertEqual(error.description, "Composed.Error")
    }

    func test_debug_string_convertible() {
        let error = Composed.Error(code: 11, text: "three")
        XCTAssertEqual(error.debugDescription, "Composed.Error [11]: three")
    }
}
