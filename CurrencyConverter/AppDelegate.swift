import UIKit

let ratesURL = URL(string: "http://api.fixer.io/latest?base=EUR")!

struct State: RootComponent {
    private var inputText: String? = "100"
    private var rate: Double? = nil
    
    enum Message {
        case setInputText(String?)
        case dataReceived(Data?)
        case reload
    }
    
    mutating func send(_ message: Message) -> [Command<Message>] {
        switch message {
        case .setInputText(let text):
            inputText = text
            return []
        case .dataReceived(let data):
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String:Any],
                let dataDict = dict["rates"] as? [String:Double] else { return [] }
            self.rate = dataDict["USD"]
            return []
        case .reload:
            return [.request(URLRequest(url: ratesURL), available: Message.dataReceived)]
        }
    }
    
    var inputAmount: Double? {
        guard let text = inputText, let number = Double(text) else {
            return nil
        }
        return number
    }
    
    var outputAmount: Double? {
        guard let input = inputAmount, let rate = rate else { return nil }
        return input * rate
    }
    
    var viewController: ViewController<State.Message> {
        return .viewController(View.stackView(views: [
            View.textField(text: inputText ?? "", backgroundColor: inputAmount == nil ? .red : .white, onChange: Message.setInputText),
            View.button(text: "Reload", onTap: Message.reload),
            View.label(text: outputAmount.map { "\($0) USD" } ?? "...", font: UIFont.systemFont(ofSize: 20))
            ]))
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var driver: Driver<State>?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        driver = Driver(State())
        window?.rootViewController = driver?.viewController
        window?.makeKeyAndVisible()
        return true
    }

}

