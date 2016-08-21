import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginHelper {
	lazy var twitter: Twitter = Twitter()

	var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]? = [:]) -> Bool {
		if !twitter.hasAccounts {
			showLogin()
		} else {
			showConversations()
		}

		window!.makeKeyAndVisible()

		return true
	}

	func application(_ application: UIApplication, open url: URL, options: [String : AnyObject]) -> Bool {
		twitter.loginHelper = self
		twitter.handleLoginResponse(url.queryDictionary)
		return true
	}

	func client(_ client: Client, encounteredOAuthURL URL: Foundation.URL) {
		// do nothing
	}

	func client(_ client: Client, completedLoginAttempt successfully: Bool, forSession session: Session) {
		if successfully {
			showConversations()
		}
	}

	func showConversations() {
		let conversationsListViewController = ConversationsListViewController<SessionController, AvatarController>(client: twitter)
		let settingsIcon = UIImage(named: "settings")
		conversationsListViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: settingsIcon, style: .plain, target: self, action: #selector(showSettings(_:)))
		conversationsListViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newConversation(_:)))
		window!.rootViewController = UINavigationController(rootViewController: conversationsListViewController)
	}

	@IBAction private func newConversation(_ sender: AnyObject? = nil) {

	}

	@IBAction private func showLogin(_ sender: AnyObject? = nil) {
		let loginViewController = LoginViewController(client: twitter)
		twitter.loginHelper = loginViewController
		window!.rootViewController = loginViewController
	}

	@IBAction private func showSettings(_ sender: AnyObject? = nil) {
		let settingsViewController = SettingsViewController(client: twitter)
		settingsViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeAfterSettings(_:)))

		let navigationController = UINavigationController(rootViewController: settingsViewController)
		window!.rootViewController!.present(navigationController, animated: true, completion: nil)
	}

	@IBAction private func closeAfterSettings(_ sender: AnyObject? = nil) {
		window!.rootViewController!.dismiss(animated: true, completion: nil)

		if twitter.sessions.isEmpty {
			showLogin()
		}
	}
}

extension URL {
	var queryDictionary: [String: AnyObject] {
        var representation = [String: AnyObject]()

        if let query = query {
            query.components(separatedBy: "&").forEach {
                let components = $0.components(separatedBy: "=")
                representation[components[0]] = components[1]
            }
        }

        return representation
	}
}
