
import XCTest

class ComposedAccessTests: XCTestCase {

    func test_composed_access_retrieve_external_variable() {
        let expect = self.expectation(description: "composed access")
        let startingVal = 5
        var finalResult: Int = 0

        Composed(
            Composed.Access(startingVal),
            multiply(5)
        ).execute {
            finalResult = $0 as! Int
            expect.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertEqual(finalResult, 25)
        }
    }

    func multiply(_ num: Int) -> Composed.Action {
        return { value, completion in
            let value = (value as? Int ?? 0) * num
            completion(value)
        }
    }
}
