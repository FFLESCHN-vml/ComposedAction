
import XCTest

class ComposedActionTests: XCTestCase {

    func test_execute_simple_action_chain() {
        let expect = self.expectation(description: "simple captured value")
        let captured = Captured<String>()

        Composed(
            .action(cat("dub-dub")),
            .action(uppercase()),
            .action(prefix("-lubba-")),
            .action(prefix("wubba")),
            .action(cat("!")),
            .action(printValue),
            .action(captureValue(expect, captured))
        ).execute()

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(captured.value, "wubba-lubba-DUB-DUB!")
        }
    }

    func test_execute_compound_action_chain() {
        let expect = self.expectation(description: "compound captured value")
        let captured = Captured<Int>()

        let totalup10 = Composed(.action(addition(6)), .action(addition(4)))
        let subtract7 = Composed(.action(addition(-5)), .action(addition(-2)))

        Composed(
            .action(totalup10.action),
            .action(totalup10.action),
            .action(subtract7.action),
            .action(printValue),
            .action(captureValue(expect, captured))
        ).execute()

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(captured.value, 13)
        }
    }

    func test_execute_sub_actions_accept_current_value_but_pass_original_value_forward() {
        let expect = self.expectation(description: "outer actions")
        let subexpect = self.expectation(description: "sub action")
        let subcapture = Captured<Int>()
        let startingVal = 555
        var finalResult: Int = 0

        Composed(
            .access(startingVal),
            .action(addition(-55)),
            .sub([
                .action(addition(-100)),
                .action(captureValue(subexpect, subcapture))
                ])
            ).execute {
                finalResult = $0 as! Int
                expect.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertEqual(subcapture.value, 400)
            XCTAssertEqual(finalResult, 500)
        }
    }

    func test_stops_on_error() {
        let expect = self.expectation(description: "stops on error")
        let captured = Captured<Int>()

        Composed(
            .action(addition(25)),
            .action(addition(25)),
            .action(generateError),
            .action(captureValue(expect, captured))
        )
            .stopOnError { _ in expect.fulfill() }
            .execute()

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(captured.value)
        }
    }

    func test_continues_on_error() {
        let expect = self.expectation(description: "stops on error")
        let captured = Captured<Any>()

        Composed(
            .action(addition(25)),
            .action(addition(25)),
            .action(generateError),
            .action(captureValue(expect, captured))
        ).execute()

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNotNil(captured.value)
            XCTAssert(captured.value is Error)
        }
    }

    func test_runs_final_handler() {
        let expect = self.expectation(description: "finalAction on execute")
        let captured = Captured<Int>()

        Composed(
            .action(addition(5)),
            .action(addition(10))
        ).execute {
            captured.value = $0 as? Int
            expect.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(captured.value, 15)
        }
    }

    func test_composed_access_retrieve_external_variable() {
        let expect = self.expectation(description: "composed access")
        let startingVal = 5
        var finalResult: Int = 0

        Composed(
            .access(startingVal),
            .action(multiply(5))
            ).execute {
                finalResult = $0 as! Int
                expect.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertEqual(finalResult, 25)
        }
    }

    func test_is_reusable() {
        let expect = self.expectation(description: "reusable")
        var finalResult: Int = 0

        let composed = Composed(
            .action(addition(5)),
            .action(multiply(5))
        )

        composed.execute {
            finalResult += $0 as! Int
            composed.execute {
                finalResult += $0 as! Int
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertEqual(finalResult, 50)
        }
    }
}
