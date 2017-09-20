
import Foundation

class Composed {

    typealias Action = (Any?, @escaping Completion)->()
    typealias Completion = (Any?)->()
    typealias ErrorHandler = (Error?)->()

    fileprivate var actions: [Action] = []
    fileprivate var errorHandler: ErrorHandler?

    init(_ actions: Action...) {
        self.actions = actions.reversed()
    }

    class Error: Swift.Error, CustomStringConvertible, CustomDebugStringConvertible {
        let code: Int
        let text: String
        var description: String { return "Composed.Error" }
        var debugDescription: String { return "\(self) [\(code)]: \(text)" }
        init(code: Int, text: String) { self.code = code; self.text = text }
        convenience init() { self.init(code: -1, text: "Undefined Error") }
    }
}


// MARK: - General Operation
extension Composed {

    func action() -> Action {
        return { incomingVal, finalCompletion in
            let finalAction: Action = { val, _ in
                finalCompletion(val)
            }
            self.actions.insert(finalAction, at: 0)
            self.actionCompletion(incomingVal)
        }
    }

    func execute(_ finalHandler: Completion? = nil) {
        if let finalHandler = finalHandler {
            let finalAction: Action = { val, _ in
                finalHandler(val)
            }
            self.actions.insert(finalAction, at: 0)
        }
        actionCompletion(nil)
    }

    func stopOnError(_ handler: ErrorHandler? = nil) -> Composed {
        errorHandler = { error in
            handler?(error)
            self.actions = []
        }
        return self
    }

    private func actionCompletion(_ value: Any?) {
        if let errorHandler = self.errorHandler,
            let value = value as? Error {
            return errorHandler(value)
        }
        guard let nextAction = actions.popLast() else { return }
        nextAction(value, actionCompletion)
    }
}


// MARK: - Convenient Actions
extension Composed {

    static func Access(_ something: Any?) -> Composed.Action {
        return { _, completion in  completion(something) }
    }
}
