
import Foundation

class Composed {

    typealias Action = (Any?, @escaping Completion)->()
    typealias Completion = (Any?)->()
    typealias ErrorHandler = (Swift.Error?)->()

    fileprivate var actions: [ActionItem] = []
    fileprivate var errorHandler: ErrorHandler?

    init(_ actions: ActionItem...) {
        self.actions = actions
    }

    init(actions: [ActionItem]) {
        self.actions = actions
    }

    enum ActionItem {
        case action(Action)
        case access(Any?)
        case sub([ActionItem])
        var closure: Action {
            switch (self) {
            case let .action(closure):      return closure
            case let .access(something):    return { _, completion in  completion(something) }
            case let .sub(actions):
                return { val, completion in
                    var actions = actions
                    actions.insert((.access(val)), at: 0)
                    Composed(actions: actions).execute { _ in completion(val) }
                }
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
        return { initialVal, finalCompletion in
            self.appendFinalHandlerForAction(finalCompletion)
            self.actionCompletion(initialVal)
        }
    }

    func execute(_ finalHandler: Completion? = nil) {
        appendFinalHandlerForExecution(finalHandler)
        actionCompletion(nil)
    }

    func stopOnError(_ handler: ErrorHandler? = nil) -> Composed {
        errorHandler = { error in
            handler?(error)
            self.actions = []
        }
        return self
    }
}


// MARK: -
fileprivate extension Composed {
    func appendFinalHandlerForAction(_ finalCompletion: @escaping Completion) {
        let finalAction: ActionItem = .action({ val,_ in finalCompletion(val) })
        self.actions.append(finalAction)
    }

    func appendFinalHandlerForExecution(_ finalHandler: Completion?) {
        let finalAction: ActionItem
        if let finalHandler = finalHandler { finalAction = .action({ val, _ in finalHandler(val) }) }
        else { finalAction = .action({ $1($0) }) }
        self.actions.append(finalAction)
    }

    func actionCompletion(_ value: Any?) {
        if let errorHandler = self.errorHandler,
            let value = value as? Swift.Error {
            return errorHandler(value)
        }
        guard let nextAction = getNextAction() else { return }
        nextAction.closure(value, actionCompletion)
    }

    func getNextAction() -> ActionItem? {
        guard !(actions .isEmpty) else { return nil }
        return actions.removeFirst()
    }
}
