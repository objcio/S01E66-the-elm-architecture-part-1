import UIKit

public struct Button<Action> {
    public let text: String
    public let onTap: Action?
    
    public init(text: String, onTap: Action? = nil) {
        self.text = text
        self.onTap = onTap
    }
    
    func map<B>(_ transform: (Action) -> B) -> Button<B> {
        return Button<B>(text: text, onTap: onTap.map(transform))
    }
}

public struct TextField<Action> {
    public let text: String
    public let backgroundColor: UIColor
    public let onChange: ((String?) -> Action)?
    
    
    public init(text: String, backgroundColor: UIColor, onChange: ((String?) -> Action)? = nil) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.onChange = onChange
    }
    
    func map<B>(_ transform: @escaping (Action) -> B) -> TextField<B> {
        return TextField<B>(text: text, backgroundColor: backgroundColor, onChange: onChange.map { x in { transform(x($0)) } })
    }
}

public struct StackView<A> {
    public let views: [View<A>]
    public let axis: UILayoutConstraintAxis
    public let distribution: UIStackViewDistribution
    public let backgroundColor: UIColor
    public init(views: [View<A>], axis: UILayoutConstraintAxis = .vertical, distribution: UIStackViewDistribution = .equalCentering, backgroundColor: UIColor = .white) {
        self.views = views
        self.axis = axis
        self.distribution = distribution
        self.backgroundColor = backgroundColor
    }
    
    func map<B>(_ transform: @escaping (A) -> B) -> StackView<B> {
        return StackView<B>(views: views.map { view in view.map(transform) }, axis: axis, distribution: distribution, backgroundColor: backgroundColor)
    }
}

public struct TableView<A> {
    public let items: [TableViewCell<A>]
    
    public init(items: [TableViewCell<A>]) {
        self.items = items
    }

    func map<B>(_ transform: @escaping (A) -> B) -> TableView<B> {
        return TableView<B>(items: items.map( { item in item.map(transform) }))
    }
}

public struct TableViewCell<Action>: Hashable {
    public static func ==(lhs: TableViewCell<Action>, rhs: TableViewCell<Action>) -> Bool {
        return lhs.identity == rhs.identity && lhs.text == rhs.text && lhs.accessory == rhs.accessory
    }
    public var hashValue: Int {
        return identity.hashValue
    }
    
    public let identity: AnyHashable
    public let text: String
    public let onSelect: Action?
    public let onDelete: Action?
    public let accessory: UITableViewCellAccessoryType
    public init(identity: AnyHashable, text: String, onSelect: Action?, accessory: UITableViewCellAccessoryType = .none, onDelete: Action?) {
        self.identity = identity
        self.text = text
        self.accessory = accessory
        self.onSelect = onSelect
        self.onDelete = onDelete
    }
    
    func map<B>(_ transform: @escaping (Action) -> B) -> TableViewCell<B> {
        return TableViewCell<B>(identity: identity, text: text, onSelect: onSelect.map(transform), onDelete: onDelete.map(transform))
    }
}

public struct Slider<Action> {
    public let progress: Float
    public let max: Float
    public let onChange: ((Float) -> Action)?
    public init(progress: Float, max: Float = 1, onChange: ((Float) -> Action)? = nil) {
        self.progress = progress
        self.max = max
        self.onChange = onChange
    }
    
    func map<B>(_ transform: @escaping (Action) -> B) -> Slider<B> {
        return Slider<B>(progress: progress, max: max, onChange: onChange.map { o in { value in transform(o(value)) } })
    }
}

public enum BarButtonItem<Message> {
    case none
    case builtin(UIBarButtonItem)
    case system(UIBarButtonSystemItem, action: Message)
    case custom(text: String, action: Message)
    case editButtonItem
    
    func map<B>(_ transform: (Message) -> B) -> BarButtonItem<B> {
        switch self {
        case let .builtin(b):
            return .builtin(b)
        case let .system(i, action: message):
            return .system(i, action: transform(message))
        case let .custom(text: text, action: action):
            return .custom(text: text, action: transform(action))
        case .editButtonItem:
            return .editButtonItem
        case .none:
            return .none
        }
    }
}

public indirect enum ViewController<Message> {
    case viewController(View<Message>)
    case tableViewController(TableView<Message>)
    case _navigationController(NavigationController<Message>)
    case splitViewController(SplitViewController<Message>, modal: Modal<Message>?) // todo modal should really be a property of ViewController
    
    func map<B>(_ transform: @escaping (Message) -> B) -> ViewController<B> {
        switch self {
        case ._navigationController(let nc): return ._navigationController(nc.map(transform))
        case .tableViewController(let tc): return .tableViewController(tc.map(transform))
        case .viewController(let vc): return .viewController(vc.map(transform))
        case .splitViewController(let sc, let modal): return .splitViewController(sc.map(transform), modal: modal?.map(transform))
        }
    }
    
    static func navigationController(viewControllers: [NavigationItem<Message>]) -> ViewController<Message> {
        return ._navigationController(NavigationController(viewControllers: viewControllers))
    }
}

public struct NavigationController<Message> {
    var viewControllers: [NavigationItem<Message>]
    var back: Message?
    var popDetail: Message?
    
    public init(viewControllers: [NavigationItem<Message>], back: Message? = nil, popDetail: Message? = nil) {
        self.viewControllers = viewControllers
        self.back = back
        self.popDetail = popDetail
    }
    
    public func map<B>(_ transform: @escaping (Message) -> B) -> NavigationController<B> {
        return NavigationController<B>(viewControllers: viewControllers.map { vc in vc.map(transform) }, back: back.map(transform), popDetail: popDetail.map(transform))
    }
}

public struct SplitViewController<Message> {
    let left: (UIBarButtonItem?) -> NavigationController<Message>
    let right: (UIBarButtonItem?) -> NavigationController<Message>
    let collapseSecondaryViewController: Bool
    let popDetail: Message?
    
    func map<B>(_ transform: @escaping (Message) -> B) -> SplitViewController<B> {
        return SplitViewController<B>(left: { self.left($0).map(transform) }, right: { self.right($0).map(transform) }, collapseSecondaryViewController: collapseSecondaryViewController, popDetail: popDetail.map(transform))
    }
}


indirect public enum View<A> {
    case _button(Button<A>)
    case _textfield(TextField<A>)
    case label(text: String, font: UIFont)
    case imageView(image: UIImage?)
    case _stackView(StackView<A>)
    case _slider(Slider<A>)
    case tableView(TableView<A>)
    case space(width: CGFloat?, height: CGFloat?)
    case activityIndicator(style: UIActivityIndicatorViewStyle)
    
    func map<B>(_ transform: @escaping (A) -> B) -> View<B> {
        switch self {
        case ._button(let b):
            return ._button(b.map(transform))
        case ._textfield(let t):
            return ._textfield(t.map(transform))
        case let .label(text, font):
            return .label(text: text, font: font)
        case let .imageView(image: img):
            return .imageView(image: img)
        case let ._stackView(s):
            return ._stackView(s.map(transform))
        case let ._slider(s):
            return ._slider(s.map(transform))
        case let .tableView(t):
            return .tableView(t.map(transform))
        case let .space(width, height):
            return .space(width: width, height: height)
        case let .activityIndicator(style):
            return .activityIndicator(style: style)
        }
    }
}

extension View {
    public static func stackView(views: [View<A>], axis: UILayoutConstraintAxis = .vertical, distribution: UIStackViewDistribution = .equalCentering, backgroundColor: UIColor = .white) -> View<A> {
        return ._stackView(StackView(views: views, axis: axis, distribution: distribution, backgroundColor: backgroundColor))
    }
    
    public static func button(text: String, onTap: A? = nil) -> View<A> {
        return ._button(Button(text: text, onTap: onTap))
    }
    
    public static func slider(progress: Float, max: Float = 1, onChange: ((Float) -> A)? = nil) -> View<A> {
        return ._slider(Slider(progress: progress, max: max, onChange: onChange))
    }
    
    public static func textField(text: String, backgroundColor: UIColor = .white, onChange: ((String?) -> A)? = nil) -> View<A> {
        return ._textfield(TextField(text: text, backgroundColor: backgroundColor, onChange: onChange))
    }
}

public struct Modal<Message> {
    let viewController: ViewController<Message>
    let presentationStyle: UIModalPresentationStyle
    
    func map<B>(_ transform: @escaping (Message) -> B) -> Modal<B> {
        return Modal<B>(viewController: viewController.map(transform), presentationStyle: presentationStyle)
    }
}

public struct NavigationItem<Message> {
    let title: String
    let leftBarButtonItem: BarButtonItem<Message>?
    let rightBarButtonItems: [BarButtonItem<Message>]
    let leftItemsSupplementsBackButton: Bool
    let viewController: ViewController<Message>
    
    public init(title: String = "", leftBarButtonItem: BarButtonItem<Message>? = nil, rightBarButtonItems: [BarButtonItem<Message>] = [], leftItemsSupplementsBackButton: Bool = false, viewController: ViewController<Message>) {
        self.title = title
        self.leftBarButtonItem = leftBarButtonItem
        self.rightBarButtonItems = rightBarButtonItems
        self.leftItemsSupplementsBackButton = leftItemsSupplementsBackButton
        self.viewController = viewController
    }
    
    func map<B>(_ transform: @escaping (Message) -> B) -> NavigationItem<B> {
        return NavigationItem<B>(title: title, leftBarButtonItem: leftBarButtonItem?.map(transform), rightBarButtonItems: rightBarButtonItems.map { btn in btn.map(transform) }, leftItemsSupplementsBackButton: leftItemsSupplementsBackButton, viewController: viewController.map(transform))
    }
}
