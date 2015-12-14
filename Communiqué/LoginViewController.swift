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

		view.backgroundColor = UIColor.whiteColor()

		let button = UIButton(type: .Custom)
		button.addTarget(self, action: "login:", forControlEvents: [ .TouchUpInside ])
		button.setTitle("Log In", forState: .Normal)
		button.setTitleColor(UIColor.blackColor(), forState: [ .Normal ])

		button.titleLabel?.font = UIFont.systemFontOfSize(24.0, weight: UIFontWeightLight)

		view.addSubview(button)

		button.sizeToFit()

		button.center = view.center
	}

	@IBAction private func login(sender: AnyObject?) {
		client.login()
	}
}

extension LoginViewController: LoginHelper {
	public func client(client: Client, encounteredOAuthURL URL: NSURL) {
		UIApplication.sharedApplication().openURL(URL)
	}

	public func client(client: Client, completedLoginAttempt successfully: Bool, forSession session: Session) {
		// do nothing
	}
}
