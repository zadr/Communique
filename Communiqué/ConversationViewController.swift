import Foundation
import UIKit

class ConversationListViewController: UITableViewController, SessionDisplay {
	let sessionController: SessionController
	let avatarController: AvatarProvider
	let people: [Person]

	lazy var textField = UITextField()

	let id: String = UUID().uuidString

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

		view.backgroundColor = UIColor.white

		title = people.map({ return $0.displayValue }).joined(separator: ", ")
		tableView.tableFooterView = UIView()

		refreshControl = UIRefreshControl()
		refreshControl!.addTarget(self, action: #selector(refresh(_:)), for: [ .valueChanged ])
		tableView.addSubview(refreshControl!)

		textField.autoresizingMask = [ .flexibleWidth, .flexibleRightMargin ]
		textField.borderStyle = .roundedRect
		textField.backgroundColor = .white
		textField.layer.borderWidth = 1.0
		textField.layer.borderColor = UIColor.lightGray.cgColor
		textField.layer.cornerRadius = 3.0

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

		toolbarItems = [
			UIBarButtonItem(customView: textField),
			UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(done(_:)))
		]
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		textField.resignFirstResponder()

		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}

	@objc private func keyboardWillShow(_ notification: Notification) {
		let keyboardRectValue = (notification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
		let keyboardRect = keyboardRectValue.cgRectValue

		let animationDurationValue = (notification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
		let animationDuration = animationDurationValue.doubleValue

		let animationCurveValue = (notification).userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
		let animationCurve = UIViewAnimationOptions(rawValue: animationCurveValue.uintValue)

		UIView.animate(withDuration: animationDuration, delay: 0.0, options: animationCurve, animations: { [ weak self] in
			guard let this = self else { return }

			var frame = this.navigationController!.view.frame
			frame.size.height = keyboardRect.minY
			this.navigationController!.view.frame = frame
		}, completion: nil)
	}

	@objc private func keyboardWillHide(_ notification: Notification) {
		let animationDurationValue = (notification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
		let animationDuration = animationDurationValue.doubleValue

		let animationCurveValue = (notification).userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
		let animationCurve = UIViewAnimationOptions(rawValue: animationCurveValue.uintValue)

		UIView.animate(withDuration: animationDuration, delay: 0.0, options: animationCurve, animations: { [weak self] in
			guard let this = self else { return }
			guard let _ = this.navigationController else { return }

			this.resetNavigationControllerFrame()
		}, completion: nil)
	}

	private func resetNavigationControllerFrame() {
		var frame = navigationController!.view.frame
		frame.size.height = UIApplication.shared.keyWindow!.frame.height
		navigationController!.view.frame = frame
	}

	@IBAction private func refresh(_ sender: AnyObject? = nil) {
		sessionController.fetch()
	}

	@IBAction private func done(_ sender: AnyObject? = nil) {
		textField.resignFirstResponder()

		if let text = textField.text, text.utf8.count > 0 {
			sessionController.post(.personalMessages, message: text, to: people.first!)
		}

		textField.text = nil
	}

	override func viewWillAppear(_ animated: Bool) {
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

	func sessionController(_ sessionController: SessionController, didLoadItems items: [Item], forFeed: FeedType) {
		tableView.reloadData()
		refreshControl!.endRefreshing()
	}

	private var items: [Item] {
        let items = sessionController.itemsForFeedType(.personalMessages)
        return items.filter({
            let to = people.contains($0.sender)
            let from = $0.people == people

            return to || from
        }).sorted(by: { (first, second) -> Bool in
            return first.id > second.id
        })
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let item = items.reversed()[indexPath.row]

		// WARNING: ugly
		if item.sender.username == sessionController.session.username {
			return [
				UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) -> () in
					self.sessionController.remove(item, type: .personalMessages)
				})
			]
		}

		return nil
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let cell = self.tableView(tableView, cellForRowAt: indexPath)

		cell.setNeedsLayout()
		cell.layoutIfNeeded()

		return 20.0 + max(cell.detailTextLabel!.frame.size.height, cell.imageView!.frame.size.height)
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? MessageCell
		if cell == nil {
			cell = MessageCell(style: .subtitle, reuseIdentifier: "cell")
			cell?.detailTextLabel?.numberOfLines = 0
		}

		cell?.separatorInset = UIEdgeInsets.zero

		let item = items.reversed()[indexPath.row]
		let previousItem = items.reversed()[max(0, indexPath.row - 1)]

		// WARNING: ugly
		cell?.imageOnLeft = item.sender.username != sessionController.session.username

		if indexPath.row == 0 || previousItem.sender != item.sender {
			cell!.imageView!.image = avatarController.avatar(item.sender) { (avatar) -> () in
				tableView.reloadRows(at: [ indexPath ], with: .fade)

				cell!.setNeedsLayout()
			}
		} else {
			cell!.imageView!.image = nil
		}

		cell?.detailTextLabel?.text = item.message

		return cell!
	}
}
