import UIKit

class ConversationsListViewController<T: SessionController, U: AvatarProvider>: UITableViewController, SessionDisplay {
	let client: Client
	let sessionController: [T]
	var activeSessionController: T

	let avatarController: U
	let id: String = UUID().uuidString

	init(client: Client) {
		self.client = client

		avatarController = U()
		sessionController = client.sessions.map({ return T(session: $0, feedTypes: [ .personalMessages ]) })
		activeSessionController = sessionController.first!

		super.init(nibName: nil, bundle: nil)

		sessionController.forEach({
			$0.addObserver(self)
			$0.fetch()
		})
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	deinit {
		sessionController.forEach({
			$0.removeObserver(self)
		})
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = activeSessionController.title
		tableView.tableFooterView = UIView()

		refreshControl = UIRefreshControl()
		refreshControl!.addTarget(self, action: #selector(refresh(_:)), for: [ .valueChanged ])
		tableView.addSubview(refreshControl!)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		navigationController?.setToolbarHidden(true, animated: true)
	}

	func sessionController(_ sessionController: SessionController, didLoadItems items: [Item], forFeed: FeedType) {
		if sessionController != activeSessionController {
			return
		}

		tableView.reloadData()
		refreshControl!.endRefreshing()
	}

	@IBAction fileprivate func refresh(_ sender: AnyObject? = nil) {
		sessionController.forEach { $0.fetch() }
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let items = activeSessionController.itemsForFeedType(.personalMessages)
		return items.map({ return $0.sender }).unique().count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
		if cell == nil {
			cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
		}

		let items = activeSessionController.itemsForFeedType(.personalMessages)
		let people = items.map({ return $0.sender }).unique()
		let person = people[(indexPath as NSIndexPath).row]

		let item: Item = {
			var item: Item? = nil
			items.reversed().forEach({
				if $0.sender == person {
					item = $0
					return
				}
			})

			return item!
		}()

		cell?.textLabel?.text = person.displayValue
		cell?.detailTextLabel?.text = item.message

		cell?.imageView?.layer.masksToBounds = true
		cell?.imageView?.layer.setAffineTransform(CGAffineTransform(scaleX: 0.65, y: 0.65))
		cell?.imageView?.image = avatarController.avatar(person) { (avatar) -> () in
			tableView.reloadRows(at: [ indexPath ], with: .fade)
		}

		if let image = cell?.imageView?.image {
			cell?.imageView?.layer.cornerRadius = image.size.width / 2.0
		}

		return cell!
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let items = activeSessionController.itemsForFeedType(.personalMessages)
		let people = items.map({ return $0.sender }).unique()
		let person = people[indexPath.row]

		return [
			UITableViewRowAction(style: .default, title: "Block", handler: { (action, indexPath) -> () in
				self.activeSessionController.block(person)
			}),
			UITableViewRowAction(style: .default, title: "Spam", handler: { (action, indexPath) -> () in
				self.activeSessionController.reportSpam(person)
			})
		]
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let items = activeSessionController.itemsForFeedType(.personalMessages)
		let people = items.map({ return $0.sender }).unique()
		let person = people[(indexPath as NSIndexPath).row]

		let conversationViewController = ConversationListViewController(sessionController: activeSessionController, avatarController: avatarController, people: [person])
		navigationController!.pushViewController(conversationViewController, animated: true)

		tableView.deselectRow(at: indexPath, animated: true)
	}
}
