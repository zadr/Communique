import UIKit

class SettingsViewController: UITableViewController {
	var client: Client

	init(client: Client) {
		self.client = client

		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) { abort() }

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.tableFooterView = UIView()
		title = "Settings"
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		if client.sessions.isEmpty {
			return 2
		}

		return 3
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 && !client.sessions.isEmpty {
			return client.sessions.count
		}

		return 1
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
		}

		if indexPath.section == 0 && !client.sessions.isEmpty {
			let session = client.sessions[indexPath.row]
			cell?.textLabel?.text = session.title
			cell?.textLabel?.textAlignment = .left
		} else if indexPath.section == 1 || client.sessions.isEmpty {
			cell?.textLabel?.text = "Add New Account"
			cell?.textLabel?.textAlignment = .center
		} else {
			cell?.textLabel?.text = "Show User Names"
			cell?.textLabel?.textAlignment = .left

			let switchView = UISwitch()
			switchView.addTarget(self, action: #selector(displayNamesToggled(_:)), for: [ .valueChanged ])
			switchView.isOn = UserDefaults.standard.bool(forKey: "show-user-names")
			cell?.accessoryView = switchView
		}

		return cell!
	}

	@IBAction private func displayNamesToggled(_ sender: AnyObject? = nil) {
		let value = UserDefaults.standard.bool(forKey: "show-user-names")
		UserDefaults.standard.set(!value, forKey: "show-user-names")
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 1 || client.sessions.isEmpty {
			client.loginHelper = self
			client.login()
		}

		tableView.deselectRow(at: indexPath, animated: true)
	}

	@IBAction private func close(_ sender: AnyObject? = nil) {
		navigationController!.dismiss(animated: true, completion: nil)
	}
}

extension SettingsViewController: LoginHelper {
	func client(_ client: Client, encounteredOAuthURL URL: Foundation.URL) {
		UIApplication.shared.openURL(URL)
	}

	func client(_ client: Client, completedLoginAttempt successfully: Bool, forSession session: Session) {
		// do nothing
	}
}
