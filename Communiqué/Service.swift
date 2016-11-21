import Foundation

public protocol LoginHelper: class {
	func client(_ client: Client, encounteredOAuthURL URL: URL)
	func client(_ client: Client, completedLoginAttempt successfully: Bool, forSession session: Session)
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

	func handleLoginResponse(_ response: [String: Any])
}

public enum FeedType: Int {
	case home // all followers activity
	case userActivity // @replies, or activity feed
	case personalMessages // fileprivate messages
}

public typealias FetchResponse = ([Item]?, Error?) -> ()

public protocol Session {
	func fetch(_ feed: FeedType, since: String?, handler: FetchResponse?)
	func post(_ feed: FeedType, message: String, to: Person)
	func remove(_ item: Item, feed: FeedType)
	func block(_ person: Person)
	func reportSpam(_ person: Person)

	var title: String { get }
	var username: String { get }
}

public class Person: Equatable {
	let avatar: URL
	let displayName: String
	let username: String
	let id: String
	let when: String
	let following: Bool
	let location: String

	init(dictionary: [String: Any]) {
		avatar = URL(string: dictionary["profile_image_url_https"] as! String)!
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

	init(dictionary: [String: Any]) {
		sender = Person(dictionary: dictionary["sender"] as! [String: Any])
		people = [
			Person(dictionary: dictionary["recipient"] as! [String: Any])
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
		self.id = UUID().uuidString
	}
}

public func ==(lhs: Item, rhs: Item) -> Bool {
	return lhs.id == rhs.id
}

extension Person {
	var displayValue: String {
        if UserDefaults.standard.bool(forKey: "show-user-names") {
            return username
        }

        return displayName
	}
}
