
import XCTest

class ComposedActionTests: XCTestCase {

    class Captured<T> { var value: T? }

    func test_execute_simple_action_chain() {
        let expect = self.expectation(description: "simple captured value")
        let captured = Captured<String>()

        Composed(
            cat("dub-dub"),
            uppercase(),
            prefix("-lubba-"),
            prefix("wubba"),
            cat("!"),
            printValue,
            captureValue(expect, captured)
        ).execute()

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(captured.value, "wubba-lubba-DUB-DUB!")
        }
    }

    func test_execute_compound_action_chain() {
        let expect = self.expectation(description: "compound captured value")
        let captured = Captured<Int>()

        let totalup10 = Composed(add(6), add(4)).action()
        let subtract7 = Composed(add(-5), add(-2)).action()

        Composed(
            totalup10,
            subtract7,
            printValue,
            captureValue(expect, captured)
        ).execute()

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(captured.value, 3)
        }
    }

    func test_stops_on_error() {
        let expect = self.expectation(description: "stops on error")
        let captured = Captured<Int>()

        Composed(
            add(25),
            add(25),
            generateError,
            captureValue(expect, captured)
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
            add(25),
            add(25),
            generateError,
            captureValue(expect, captured)
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
            add(5),
            add(10)
        ).execute {
            captured.value = $0 as? Int
            expect.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(captured.value, 15)
        }
    }


    // Actions
    func add(_ num: Int) -> Composed.Action {
        return { value, completion in
            DispatchQueue.global(qos: .background).async {
                let value = (value as? Int ?? 0) + num
                completion(value)
            }
        }
    }

    func cat(_ text: String) -> Composed.Action {
        return { value, completion in
            let value = (value as? String ?? "") + text
            completion(value)
        }
    }

    func prefix(_ text: String) -> Composed.Action {
        return { value, completion in
            let value = text + (value as? String ?? "")
            completion(value)
        }
    }

    func uppercase() -> Composed.Action {
        return { value, completion in
            completion((value as? String ?? "").uppercased())
        }
    }

    var printValue: Composed.Action = { value, completion in
        DispatchQueue.global(qos: .background).async {
            guard let value = value else { return }
            print("\n--------\n\(value)\n--------\n")
            completion(value)
        }
    }

    func captureValue<T>(_ expectation: XCTestExpectation, _ captured: Captured<T>) -> Composed.Action {
        return { value, completion in
            DispatchQueue.global(qos: .background).async {
                captured.value = value as? T
                expectation.fulfill()
                completion(value)
            }
        }
    }

    var generateError: Composed.Action = { value, completion in
        DispatchQueue.global(qos: .background).async {
            completion(Composed.Error())
        }
    }
}
