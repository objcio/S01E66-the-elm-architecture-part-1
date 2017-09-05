import UIKit

public protocol RootComponent: Codable {
	associatedtype Message
	mutating func send(_: Message) -> [Command<Message>]
	var viewController: ViewController<Message> { get }
}

final public class Driver<Model> where Model: RootComponent {
	private var model: Model
	private var strongReferences: StrongReferences = StrongReferences()
	public private(set) var viewController: UIViewController = UIViewController()
	
	public init(_ initial: Model, commands: [Command<Model.Message>] = []) {
		viewController.restorationIdentifier = "objc.io.root"
		model = initial
		strongReferences = model.viewController.render(callback: self.asyncSend, change: &viewController)
		for command in commands {
			interpret(command: command)
		}
	}
		
	public func send(action: Model.Message) { // todo this should probably be in a serial queue
		let commands = model.send(action)
		refresh()
		for command in commands {
			interpret(command: command)
		}
	}
	
	func asyncSend(action: Model.Message) {
		DispatchQueue.main.async {
			self.send(action: action)
		}
	}
	
	func interpret(command: Command<Model.Message>) {
		command.interpret(viewController: viewController, callback: self.asyncSend)
	}
	
	func refresh() {
		strongReferences = model.viewController.render(callback: self.asyncSend, change: &viewController)
	}
	
	public func encodeRestorableState(_ coder: NSCoder) {
		let jsonData = try! JSONEncoder().encode(model)
		coder.encode(jsonData, forKey: "data")
	}
	
	public func decodeRestorableState(_ coder: NSCoder) {
		if let jsonData = coder.decodeObject(forKey: "data") as? Data {
			if let m = try? JSONDecoder().decode(Model.self, from: jsonData) {
				model = m
			}
		}
		refresh()
	}
}
