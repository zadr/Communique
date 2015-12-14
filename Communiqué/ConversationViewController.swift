import Foundation
import UIKit

class ConversationListViewController: UITableViewController, SessionDisplay {
	let sessionController: SessionController
	let avatarController: AvatarProvider
	let people: [Person]

	lazy var textField = UITextField()

	let id: String = NSUUID().UUIDString

	init(sessionController: SessionController, avatarController: AvatarProvider, people: [Person]) {
		self.sessionController = sessionController
		self.avatarController = avatarController
		self.people = people

		super.init(nibName: nil, bundle: nil)

		sessionController.addObserver(self)
	}

	required init?(coder aDecoder: NSCoder) { abort() }

	deinit {
		sessionController.removeObserver(self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = UIColor.whiteColor()

		title = people.map({ return $0.displayValue }).joinWithSeparator(", ")
		tableView.tableFooterView = UIView()

		refreshControl = UIRefreshControl()
		refreshControl!.addTarget(self, action: "refresh:", forControlEvents: [ .ValueChanged ])
		tableView.addSubview(refreshControl!)

		textField.autoresizingMask = [ .FlexibleWidth, .FlexibleRightMargin ]
		textField.borderStyle = .RoundedRect
		textField.backgroundColor = UIColor.whiteColor()
		textField.layer.borderWidth = 1.0
		textField.layer.borderColor = UIColor.lightGrayColor().CGColor
		textField.layer.cornerRadius = 3.0

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)

		self.toolbarItems = [
			UIBarButtonItem(customView: textField),
			UIBarButtonItem(title: "Send", style: .Plain, target: self, action: "done:")
		]
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		textField.resignFirstResponder()

		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}

	@IBAction private func keyboardWillShow(notification: NSNotification) {
		let keyboardRectValue = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
		let keyboardRect = keyboardRectValue.CGRectValue()

		let animationDurationValue = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
		let animationDuration = animationDurationValue.doubleValue

		let animationCurveValue = notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
		let animationCurve = UIViewAnimationOptions(rawValue: animationCurveValue.unsignedIntegerValue)

		UIView.animateWithDuration(animationDuration, delay: 0.0, options: animationCurve, animations: { [ weak self] in
			guard let this = self else { return }

			var frame = this.navigationController!.view.frame
			frame.size.height = CGRectGetMinY(keyboardRect)
			this.navigationController!.view.frame = frame
		}, completion: nil)
	}

	@IBAction private func keyboardWillHide(notification: NSNotification) {
		let animationDurationValue = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
		let animationDuration = animationDurationValue.doubleValue

		let animationCurveValue = notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
		let animationCurve = UIViewAnimationOptions(rawValue: animationCurveValue.unsignedIntegerValue)

		UIView.animateWithDuration(animationDuration, delay: 0.0, options: animationCurve, animations: { [weak self] in
			guard let this = self else { return }
			guard let _ = this.navigationController else { return }

			this.resetNavigationControllerFrame()
		}, completion: nil)
	}

	private func resetNavigationControllerFrame() {
		var frame = self.navigationController!.view.frame
		frame.size.height = CGRectGetHeight(UIApplication.sharedApplication().keyWindow!.frame)
		self.navigationController!.view.frame = frame
	}

	@IBAction private func refresh(sender: AnyObject? = nil) {
		sessionController.fetch()
	}

	@IBAction private func done(sender: AnyObject? = nil) {
		textField.resignFirstResponder()

		if let text = textField.text where text.utf8.count > 0 {
			sessionController.post(.PersonalMessages, message: text, to: people.first!)
		}

		textField.text = nil
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		navigationController?.setToolbarHidden(false, animated: true)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		guard let navigationController = navigationController else { return }

		var frame = textField.frame
		frame.size.width = view.frame.size.width - /*toolbarItems!.last!.width */ 35.0 - 45.0
		frame.size.height = navigationController.toolbar.frame.size.height - 15.0
		textField.frame = frame
	}

	func sessionController(sessionController: SessionController, didLoadItems items: [Item], forFeed: FeedType) {
		tableView.reloadData()
		refreshControl!.endRefreshing()
	}

	private var items: [Item] {
		get {
			let items = sessionController.itemsForFeedType(.PersonalMessages)
			return items.filter({
				let to = people.contains($0.sender)
				let from = $0.people == people

				return to || from
			}).sort({ (first, second) -> Bool in
				return first.id > second.id
			})
		}
	}

	override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		let item = items.reverse()[indexPath.row]

		// WARNING: ugly
		if item.sender.username == sessionController.session.username {
			return [
				UITableViewRowAction(style: .Default, title: "Delete", handler: { (action, indexPath) -> Void in
					self.sessionController.remove(item, type: .PersonalMessages)
				})
			]
		}

		return nil
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath)

		cell.setNeedsLayout()
		cell.layoutIfNeeded()

		return 20.0 + max(cell.detailTextLabel!.frame.size.height, cell.imageView!.frame.size.height)
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? MessageCell
		if cell == nil {
			cell = MessageCell(style: .Subtitle, reuseIdentifier: "cell")
			cell?.detailTextLabel?.numberOfLines = 0
		}

		cell?.separatorInset = UIEdgeInsetsZero

		let item = items.reverse()[indexPath.row]
		let previousItem = items.reverse()[max(0, indexPath.row - 1)]

		// WARNING: ugly
		cell?.imageOnLeft = item.sender.username != sessionController.session.username

		if indexPath.row == 0 || previousItem.sender != item.sender {
			cell!.imageView!.image = avatarController.avatar(item.sender) { (avatar) -> Void in
				tableView.reloadRowsAtIndexPaths([ indexPath ], withRowAnimation: .Fade)

				cell!.setNeedsLayout()
			}
		} else {
			cell!.imageView!.image = nil
		}

		cell?.detailTextLabel?.text = item.message

		return cell!
	}
}
