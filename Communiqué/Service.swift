import Foundation

public protocol LoginHelper: class {
	func client(client: Client, encounteredOAuthURL URL: NSURL)
	func client(client: Client, completedLoginAttempt successfully: Bool, forSession session: Session)
}

public protocol Client {
	init()

	var hasAccounts: Bool { get }
	var sessions: [Session] { get }

	func login()
	weak var loginHelper: LoginHelper? { get set } // This should be in `extension Twitter: Client`
}

public protocol OAuthClient: Client {
	var loginHelper: LoginHelper? { get set }

	func handleLoginResponse(response: [String: AnyObject])
}

public enum FeedType: Int {
	case Home // all followers activity
	case UserActivity // @replies, or activity feed
	case PersonalMessages // private messages
}

public typealias FetchResponse = ([Item]?, NSError?) -> Void

public protocol Session {
	func fetch(feed: FeedType, since: String?, handler: FetchResponse?)
	func post(feed: FeedType, message: String, to: Person)
	func remove(item: Item, feed: FeedType)
	func block(person: Person)
	func reportSpam(person: Person)

	var title: String { get }
	var username: String { get }
}

public class Person: Equatable {
	let avatar: NSURL
	let displayName: String
	let username: String
	let id: String
	let when: String
	let following: Bool
	let location: String

	init(dictionary: [String: AnyObject]) {
		avatar = NSURL(string: dictionary["profile_image_url_https"] as! String)!
		displayName = dictionary["name"] as! String
		username = dictionary["screen_name"] as! String
		id = dictionary["id_str"] as! String
		when = dictionary["created_at"] as! String
		following = dictionary["following"] as! NSNumber == kCFBooleanTrue
		location = dictionary["location"] as? String ?? ""
	}
}

public func ==(lhs: Person, rhs: Person) -> Bool {
	return lhs.id == rhs.id
}

public class Item: Equatable {
	let people: [Person]
	let sender: Person
	let message: String
	let date: String
	let id: String

	init(dictionary: [String: AnyObject]) {
		sender = Person(dictionary: dictionary["sender"] as! [String: AnyObject])
		people = [
			Person(dictionary: dictionary["recipient"] as! [String: AnyObject])
		]
		message = dictionary["text"] as! String
		date = dictionary["created_at"] as! String
		id = dictionary["id_str"] as! String
	}

	init(message: String, to: Person, from: Person) {
		self.sender = from
		self.people = [ to ]
		self.message = message
		self.date = ""
		self.id = NSUUID().UUIDString
	}
}

public func ==(lhs: Item, rhs: Item) -> Bool {
	return lhs.id == rhs.id
}

extension Person {
	var displayValue: String {
		get {
			if NSUserDefaults.standardUserDefaults().boolForKey("show-user-names") {
				return username
			}

			return displayName
		}
	}
}
