import UIKit

public class LoginViewController: UIViewController {
	var client: Client

	init(client: Client) {
		self.client = client

		super.init(nibName: nil, bundle: nil)
	}

	public required init (coder aDecoder: NSCoder) { abort() }

	public override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white

		let button = UIButton(type: .custom)
		button.addTarget(self, action: #selector(login(_:)), for: [ .touchUpInside ])
		button.setTitle("Log In", for: .normal)
		button.setTitleColor(.black, for: UIControlState())

		button.titleLabel?.font = UIFont.systemFont(ofSize: 24.0, weight: UIFontWeightLight)

		view.addSubview(button)

		button.sizeToFit()

		button.center = view.center
	}

	@IBAction private func login(_ sender: AnyObject?) {
		client.login()
	}
}

extension LoginViewController: LoginHelper {
	public func client(_ client: Client, encounteredOAuthURL URL: Foundation.URL) {
		UIApplication.shared.openURL(URL)
	}

	public func client(_ client: Client, completedLoginAttempt successfully: Bool, forSession session: Session) {
		// do nothing
	}
}
