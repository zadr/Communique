public protocol SessionDisplay: class {
	func sessionController(sessionController: SessionController, didLoadItems items: [Item], forFeed: FeedType)
	var id: String { get }
}

public protocol SessionControllerType: class {
	init(session: Session, feedTypes: [FeedType])

	func addObserver(observer: SessionDisplay)
	func removeObserver(observer: SessionDisplay)

	func fetch()
	func block(person: Person)
	func reportSpam(person: Person)
	func post(feed: FeedType, message: String, to person: Person)

	var title: String { get }
	var session: Session { get }
}

public class SessionController: NSObject, FeedLoading, SessionControllerType {
	public let session: Session
	private let feedControllers: [FeedController]

	private var observers = [SessionDisplay]()

	public required init(session: Session, feedTypes: [FeedType]) {
		self.session = session
		self.feedControllers = feedTypes.map({
			return FeedController(session: session, feedType: $0)
		})

		super.init()

		self.feedControllers.forEach({ $0.feedLoading = self })
	}

	public func remove(item: Item, type: FeedType) {
		self.session.remove(item, feed: type)
	}

	public func block(person: Person) {
		session.block(person)
		feedControllers.forEach({ $0.remove(person) })
	}

	public func reportSpam(person: Person) {
		session.reportSpam(person)
		feedControllers.forEach({ $0.remove(person) })
	}

	public func post(feedType: FeedType, message: String, to target: Person) {
		session.post(feedType, message: message, to: target)

		let feedController = feedControllers.filter({
			return $0.feedType == feedType
		}).first!

		// WARNING: hack
		let currentUser = feedController.items.filter({
			// WARNING: ugly
			$0.sender.username == session.username
		}).first!.sender

		let newItem = Item(message: message, to: target, from: currentUser)
		feedController.add(newItem)
	}

	public func itemsForFeedType(feedType: FeedType) -> [Item] {
		return feedControllers.filter({ return $0.feedType == feedType }).first!.items
	}

	public func fetch() {
		feedControllers.forEach({ $0.fetch() })
	}

	func feed(feedController: FeedController, didLoadItems items: [Item], inFeed feed: FeedType) {
		observers.forEach({
			$0.sessionController(self, didLoadItems: items, forFeed: feed)
		})
	}

	public func addObserver(observer: SessionDisplay) {
		observers.append(observer)
	}

	public func removeObserver(observer: SessionDisplay) {
		if let index = observers.indexOf({ return $0.id == observer.id }) {
			observers.removeAtIndex(index)
		}
	}

	public var title: String {
		get {
			return session.title
		}
	}
}

internal protocol FeedLoading {
	func feed(feedController: FeedController, didLoadItems items: [Item], inFeed feed: FeedType)
}

internal protocol FeedLoader {
	func fetch()
	func add(item: Item)
	func remove(person: Person)

	var feedLoading: FeedLoading? { get set }
}

internal class FeedController: FeedLoader {
	private let session: Session
	private let feedType: FeedType

	internal var feedLoading: FeedLoading?

	private var since: String?
	internal var items = [Item]()

	init(session: Session, feedType: FeedType) {
		self.session = session
		self.feedType = feedType
	}

	internal func add(item: Item) {
		items.append(item)

		if let feedLoading = feedLoading {
			feedLoading.feed(self, didLoadItems: items, inFeed: feedType)
		}
	}

	internal func remove(person: Person) {
		items = items.filter({ $0.sender != person })

		if let feedLoading = feedLoading {
			feedLoading.feed(self, didLoadItems: [], inFeed: feedType)
		}
	}

	internal func fetch() {
		session.fetch(feedType, since: since, handler: { (items: [Item]?, error: NSError?) in
			if let feedLoading = self.feedLoading, items = items {
				if !items.isEmpty {
					self.since = items.last!.date
				}

				self.items += items
				self.items = self.items.unique()

				feedLoading.feed(self, didLoadItems: items, inFeed: self.feedType)
			} else {
				print("unable to tell loader", self.feedLoading, "about new items, because:", error)
			}
		})
	}
}
