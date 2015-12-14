import UIKit

class ConversationsListViewController<T: SessionController, U: AvatarProvider>: UITableViewController, SessionDisplay {
	let client: Client
	let sessionController: [T]
	var activeSessionController: T

	let avatarController: U
	let id: String = NSUUID().UUIDString

	init(client: Client) {
		self.client = client

		avatarController = U()
		sessionController = client.sessions.map({ return T(session: $0, feedTypes: [ .PersonalMessages ]) })
		activeSessionController = sessionController.first!

		super.init(nibName: nil, bundle: nil)

		sessionController.forEach({
			$0.addObserver(self)
			$0.fetch()
		})
	}

	deinit {
		sessionController.forEach({
			$0.removeObserver(self)
		})
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = activeSessionController.title
		tableView.tableFooterView = UIView()

		refreshControl = UIRefreshControl()
		refreshControl!.addTarget(self, action: "refresh:", forControlEvents: [ .ValueChanged ])
		tableView.addSubview(refreshControl!)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		navigationController?.setToolbarHidden(true, animated: true)
	}

	func sessionController(sessionController: SessionController, didLoadItems items: [Item], forFeed: FeedType) {
		if sessionController != activeSessionController {
			return
		}

		tableView.reloadData()
		refreshControl!.endRefreshing()
	}

	@IBAction private func refresh(sender: AnyObject? = nil) {
		sessionController.forEach({ $0.fetch() })
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let items = activeSessionController.itemsForFeedType(.PersonalMessages)
		return items.map({ return $0.sender }).unique().count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "cell")
		}

		let items = activeSessionController.itemsForFeedType(.PersonalMessages)
		let people = items.map({ return $0.sender }).unique()
		let person = people[indexPath.row]

		let item: Item = {
			var item: Item? = nil
			items.reverse().forEach({
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
		cell?.imageView?.layer.setAffineTransform(CGAffineTransformMakeScale(0.65, 0.65))
		cell?.imageView?.image = avatarController.avatar(person) { (avatar) -> Void in
			tableView.reloadRowsAtIndexPaths([ indexPath ], withRowAnimation: .Fade)
		}

		if let image = cell?.imageView?.image {
			cell?.imageView?.layer.cornerRadius = image.size.width / 2.0
		}

		return cell!
	}

	override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		let items = activeSessionController.itemsForFeedType(.PersonalMessages)
		let people = items.map({ return $0.sender }).unique()
		let person = people[indexPath.row]

		return [
			UITableViewRowAction(style: .Default, title: "Block", handler: { (action, indexPath) -> Void in
				self.activeSessionController.block(person)
			}),
			UITableViewRowAction(style: .Default, title: "Spam", handler: { (action, indexPath) -> Void in
				self.activeSessionController.reportSpam(person)
			})
		]
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let items = activeSessionController.itemsForFeedType(.PersonalMessages)
		let people = items.map({ return $0.sender }).unique()
		let person = people[indexPath.row]

		let conversationViewController = ConversationListViewController(sessionController: activeSessionController, avatarController: avatarController, people: [person])
		navigationController!.pushViewController(conversationViewController, animated: true)

		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
}
