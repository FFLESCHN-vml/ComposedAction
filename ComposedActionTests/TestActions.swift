
import XCTest

class Captured<T> { var value: T? }

func captureValue<T>(_ expectation: XCTestExpectation, _ captured: Captured<T>) -> Composed.Action {
    return { value, completion in
        DispatchQueue.global(qos: .background).async {
            captured.value = value as? T
            expectation.fulfill()
            completion(value)
        }
    }
}

func add(_ num: Int) -> Composed.Action {
    return { value, completion in
        DispatchQueue.global(qos: .background).async {
            let value = (value as? Int ?? 0) + num
            completion(value)
        }
    }
}

func multiply(_ num: Int) -> Composed.Action {
    return { value, completion in
        let value = (value as? Int ?? 0) * num
        completion(value)
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

var generateError: Composed.Action = { value, completion in
    DispatchQueue.global(qos: .background).async {
        completion(NSError(domain: "error.intentional", code: 127, userInfo: nil))
    }
}
