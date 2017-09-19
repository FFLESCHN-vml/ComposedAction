
import Foundation

class Composed {

    typealias Action = (Any?, @escaping Completion)->()
    typealias Completion = (Any?)->()
    typealias ErrorHandler = (Error?)->()

    private var actions: [Action] = []
    private var errorHandler: ErrorHandler?

    init(_ actions: Action...) {
        self.actions = actions.reversed()
    }

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
            errorHandler(value)
            return
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
