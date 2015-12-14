import UIKit

class SettingsViewController: UITableViewController {
	var client: Client

	init(client: Client) {
		self.client = client

		super.init(style: .Grouped)
	}

	required init?(coder aDecoder: NSCoder) { abort() }

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.tableFooterView = UIView()
		title = "Settings"
	}

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if client.sessions.isEmpty {
			return 2
		}

		return 3
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 && !client.sessions.isEmpty {
			return client.sessions.count
		}

		return 1
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
		}

		if indexPath.section == 0 && !client.sessions.isEmpty {
			let session = client.sessions[indexPath.row]
			cell?.textLabel?.text = session.title
			cell?.textLabel?.textAlignment = .Left
		} else if indexPath.section == 1 || client.sessions.isEmpty {
			cell?.textLabel?.text = "Add New Account"
			cell?.textLabel?.textAlignment = .Center
		} else {
			cell?.textLabel?.text = "Show User Names"
			cell?.textLabel?.textAlignment = .Left

			let switchView = UISwitch()
			switchView.addTarget(self, action: "displayNamesToggled:", forControlEvents: [ .ValueChanged ])
			switchView.on = NSUserDefaults.standardUserDefaults().boolForKey("show-user-names")
			cell?.accessoryView = switchView
		}

		return cell!
	}

	@IBAction private func displayNamesToggled(sender: AnyObject? = nil) {
		let value = NSUserDefaults.standardUserDefaults().boolForKey("show-user-names")
		NSUserDefaults.standardUserDefaults().setBool(!value, forKey: "show-user-names")
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 1 || client.sessions.isEmpty {
			client.loginHelper = self
			client.login()
		}

		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	@IBAction private func close(sender: AnyObject? = nil) {
		navigationController!.dismissViewControllerAnimated(true, completion: nil)
	}
}

extension SettingsViewController: LoginHelper {
	func client(client: Client, encounteredOAuthURL URL: NSURL) {
		UIApplication.sharedApplication().openURL(URL)
	}

	func client(client: Client, completedLoginAttempt successfully: Bool, forSession session: Session) {
		// do nothing
	}
}
