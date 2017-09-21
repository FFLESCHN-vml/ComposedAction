
import Foundation

class Composed {

    typealias Action = (Any?, @escaping Completion)->()
    typealias Completion = (Any?)->()
    typealias ErrorHandler = (Swift.Error?)->()

    fileprivate var actions: [ActionWrapper] = []
    fileprivate var errorHandler: ErrorHandler?

    init(_ actions: ActionWrapper...) {
        self.actions = actions.reversed()
    }

    enum ActionWrapper {
        case action(Action)
        case access(Any)
        var closure: Action {
            switch (self) {
            case let .action(closure):   return closure
            case let .access(something): return { _, completion in  completion(something) }
            }
        }
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

    var action: Action {
        return { incomingVal, finalCompletion in
            let finalAction: ActionWrapper = .action({ val, _ in finalCompletion(val) })
            self.actions.insert(finalAction, at: 0)
            self.actionCompletion(incomingVal)
        }
    }

    func execute(_ finalHandler: Completion? = nil) {
        if let finalHandler = finalHandler {
            let finalAction: ActionWrapper = .action({ val, _ in finalHandler(val) })
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
            let value = value as? Swift.Error {
            return errorHandler(value)
        }
        guard let nextAction = actions.popLast() else { return }
        nextAction.closure(value, actionCompletion)
    }
}
