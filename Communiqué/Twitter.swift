// WARNING: update consumer key and secret
let consumerKey = ""
let consumerSecret = ""

let loggedInAccounts = "twitter-logged-in-accounts"
let oauthTokenKeychainIdentifier = "twitter-oauth-token"
let oauthTokenSecretKeychainIdentifier = "twitter-oauth-token-secret"

public class Twitter {
	public required init() {}

	public weak var loginHelper: LoginHelper?

	private lazy var keychain: KeychainEssentials = Keychain()
	private lazy var _sessions: [String: STTwitterAPI] = {
		var sessions = [String: STTwitterAPI]()

		let accountsString = self.keychain.passwordForServer(loggedInAccounts, area: "app")
		if let accounts = accountsString?.componentsSeparatedByString(",").unique() {
			for account in accounts {
				if account.utf8.count == 0 {
					continue
				}

				if let token = self.keychain.passwordForServer(account, area: oauthTokenKeychainIdentifier),
					   secret = self.keychain.passwordForServer(account, area: oauthTokenSecretKeychainIdentifier) {
						let api = STTwitterAPI(OAuthConsumerKey: consumerKey, consumerSecret: consumerSecret, oauthToken: token, oauthTokenSecret: secret)
						api.verify(account)

						sessions[account] = api
				}
			}
		}

		return sessions
	}()
}

extension Twitter: Client {
	public var sessions: [Session] {
		get {
			return Array(_sessions.values).map({ return $0 as STTwitterAPI })
		}
	}

	public var hasAccounts: Bool {
		get {
			return !self.sessions.isEmpty
		}
	}

	public func login() {
		let api = STTwitterAPI(OAuthConsumerKey: consumerKey, consumerSecret: consumerSecret)
		api.postTokenRequest({ (url: NSURL!, token: String!) -> Void in
			if let loginHelper = self.loginHelper {
				loginHelper.client(self, encounteredOAuthURL: url)

				self._sessions[token] = api
			} else {
				print("no login helper")
			}
		}, authenticateInsteadOfAuthorize: false, forceLogin: true, screenName: nil, oauthCallback: "canoe://callback") { (error: NSError!) -> Void in
			print("1. fetching oauth token: ", error)
		}
	}
}

extension Twitter: OAuthClient {
	public func handleLoginResponse(response: [String: AnyObject]) {
		print("response", response)
		guard let token = response["oauth_token"] as? String else {
			print("no token")
			return
		}
		guard let verifier = response["oauth_verifier"] as? String else {
			print("no verifier")
			return
		}
		guard let api = _sessions[token] else {
			print("no api")
			return
		}

		api.postAccessTokenRequestWithPIN(verifier, successBlock: { (oauthToken: String!, oauthTokenSecret: String!, userID: String!, username: String!) -> Void in
			var accountsString = self.keychain.passwordForServer(loggedInAccounts, area: "app") ?? ""
			if !accountsString.componentsSeparatedByString(",").contains(username) {
				accountsString += username + ","

				self.keychain.setPassword(accountsString, forServer: loggedInAccounts, area: "app", displayValue: loggedInAccounts)
			}

			self.keychain.setPassword(oauthToken, forServer: username, area: oauthTokenKeychainIdentifier, displayValue: username + oauthTokenKeychainIdentifier)
			self.keychain.setPassword(oauthTokenSecret, forServer: username, area: oauthTokenSecretKeychainIdentifier, displayValue: username + oauthTokenSecretKeychainIdentifier)

			self._sessions[username] = self._sessions.removeValueForKey(oauthToken)

			api.verify(username)

			if let loginHelper = self.loginHelper {
				loginHelper.client(self, completedLoginAttempt: true, forSession: api)
			}
		}, errorBlock: { (error: NSError!) -> Void in
			print("2. fetching oauth secret", error)

			if let loginHelper = self.loginHelper {
				loginHelper.client(self, completedLoginAttempt: false, forSession: api)
			}
		})
	}
}

// MARK: -

extension STTwitterAPI: Session {
	internal func verify(account: String) {
		self.userName = account

		self.verifyCredentialsWithUserSuccessBlock({ (_, _) -> Void in
		}, errorBlock: { (error) -> Void in
			print(self, error)
		})
	}
	public func fetch(feed: FeedType, since: String?, handler: FetchResponse?) {
		switch(feed) {
		case .Home: fetchHomeFeed(since, handler: handler)
		case .UserActivity: fetchUserActivityFeed(since, handler: handler)
		case .PersonalMessages:
			// WARNING: should probably have a barrier and only call handler once when both calls finish
			fetchUserReceivedPersonalMessagesFeed(since, handler: handler)
			fetchUserSentPersonalMessagesFeed(since, handler: handler)
		}
	}

	public func reportSpam(person: Person) {
		self.postUsersReportSpamForScreenName(person.username, orUserID: person.id, successBlock: { (_) -> Void in
			}, errorBlock: { (_) -> Void in
		})
	}

	public func block(person: Person) {
		self.postBlocksCreateWithScreenName(person.username, orUserID: person.id, includeEntities: true, skipStatus: true, successBlock: { (_) -> Void in
		}, errorBlock: { (_) -> Void in
		})
	}

	public func remove(item: Item, feed: FeedType) {
		if feed == .PersonalMessages {
			self.postDestroyDirectMessageWithID(item.id, includeEntities: true, successBlock: { (_) -> Void in
			}, errorBlock: { (_) -> Void in
			})
		}
	}

	public func post(feed: FeedType, message: String, to person: Person) {
		if feed == .PersonalMessages {
			self.postDirectMessage(message, forScreenName: person.username, orUserID: person.id, successBlock: { (_) -> Void in
			}, errorBlock: { (_) -> Void in
			})
		}
	}


	func fetchHomeFeed(since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		self.getHomeTimelineSinceID(since, count: limit, successBlock: { (activity) -> Void in
			let items = activity.map({ return Item(dictionary: $0 as! [String: AnyObject]) })
			if let handler = handler { handler(items, nil) }
		}) { (error: NSError!) -> Void in
			if let handler = handler { handler(nil, error) }
			print("unable to fetch home feed", error)
		}
	}

	func fetchUserActivityFeed(since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		self.getMentionsTimelineSinceID(since, count: limit, successBlock: { (activity) -> Void in
			let items = activity.map({ return Item(dictionary: $0 as! [String: AnyObject]) })
			if let handler = handler { handler(items, nil) }
		}) { (error: NSError!) -> Void in
			if let handler = handler { handler(nil, error) }
			print("unable to fetch activity feed", error)
		}
	}

	func fetchUserReceivedPersonalMessagesFeed(since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		self.getDirectMessagesSinceID(since, count: limit, successBlock: { (mentions) -> Void in
			let items = mentions.map({ return Item(dictionary: $0 as! [String: AnyObject]) })
			if let handler = handler { handler(items, nil) }
		}) { (error: NSError!) -> Void in
			if let handler = handler { handler(nil, error) }
			print("unable to direct mentions", error)
		}
	}

	func fetchUserSentPersonalMessagesFeed(since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		self.getDirectMessagesSinceID(since, maxID: nil, count: String(limit), fullText: true, page: nil, includeEntities: true, successBlock: { (mentions) -> Void in
			let items = mentions.map({ return Item(dictionary: $0 as! [String: AnyObject]) })
			if let handler = handler { handler(items, nil) }
		}) { (error) -> Void in
			if let handler = handler { handler(nil, error) }
			print("unable to direct mentions", error)
		}
	}

	public var title: String {
		get {
			return userName
		}
	}

	public var username: String {
		get {
			return userName
		}
	}
}
