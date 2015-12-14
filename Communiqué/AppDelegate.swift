import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginHelper {
	lazy var twitter: Twitter = Twitter()

	lazy var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		if !twitter.hasAccounts {
			showLogin()
		} else {
			showConversations()
		}

		window!.makeKeyAndVisible()

		return true
	}

	func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
		twitter.loginHelper = self
		twitter.handleLoginResponse(url.queryDictionary)
		return true
	}

	func client(client: Client, encounteredOAuthURL URL: NSURL) {
		// do nothing
	}

	func client(client: Client, completedLoginAttempt successfully: Bool, forSession session: Session) {
		if successfully {
			showConversations()
		}
	}

	func showConversations() {
		let conversationsListViewController = ConversationsListViewController<SessionController, AvatarController>(client: twitter)
		let settingsIcon = UIImage(named: "settings")
		conversationsListViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: settingsIcon, style: .Plain, target: self, action: "showSettings:")
		conversationsListViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "newConversation:")
		window!.rootViewController = UINavigationController(rootViewController: conversationsListViewController)
	}

	@IBAction private func newConversation(sender: AnyObject? = nil) {

	}

	@IBAction private func showLogin(sender: AnyObject? = nil) {
		let loginViewController = LoginViewController(client: twitter)
		twitter.loginHelper = loginViewController
		window!.rootViewController = loginViewController
	}

	@IBAction private func showSettings(sender: AnyObject? = nil) {
		let settingsViewController = SettingsViewController(client: twitter)
		settingsViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "closeAfterSettings:")

		let navigationController = UINavigationController(rootViewController: settingsViewController)
		window!.rootViewController!.presentViewController(navigationController, animated: true, completion: nil)
	}

	@IBAction private func closeAfterSettings(sender: AnyObject? = nil) {
		window!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)

		if twitter.sessions.isEmpty {
			showLogin()
		}
	}
}

extension NSURL {
	var queryDictionary: [String: AnyObject] {
		get {
			var representation = [String: AnyObject]()

			if let query = query {
				query.componentsSeparatedByString("&").forEach({
					let components = $0.componentsSeparatedByString("=")
					representation[components[0]] = components[1]
				})
			}

			return representation
		}
	}
}