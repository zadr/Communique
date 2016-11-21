// WARNING: update consumer key and secret
let consumerKey = ""
let consumerSecret = ""

let loggedInAccounts = "twitter-logged-in-accounts"
let oauthTokenKeychainIdentifier = "twitter-oauth-token"
let oauthTokenSecretKeychainIdentifier = "twitter-oauth-token-secret"

public class Twitter {
	public required init() {}

	public weak var loginHelper: LoginHelper?

	fileprivate lazy var keychain: KeychainEssentials = Keychain()
	fileprivate lazy var _sessions: [String: STTwitterAPI] = {
		var sessions = [String: STTwitterAPI]()

		let accountsString = self.keychain.passwordForServer(loggedInAccounts, area: "app")
		if let accounts = accountsString?.components(separatedBy: ",").unique() {
			for account in accounts {
				if account.utf8.count == 0 {
					continue
				}

				if let token = self.keychain.passwordForServer(account, area: oauthTokenKeychainIdentifier),
					   let secret = self.keychain.passwordForServer(account, area: oauthTokenSecretKeychainIdentifier) {
						let api = STTwitterAPI(oAuthConsumerKey: consumerKey, consumerSecret: consumerSecret, oauthToken: token, oauthTokenSecret: secret)
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
        return Array(_sessions.values).map({ return $0 as STTwitterAPI })
	}

	public var hasAccounts: Bool {
        return !sessions.isEmpty
	}

	public func login() {
		let api = STTwitterAPI(oAuthConsumerKey: consumerKey, consumerSecret: consumerSecret)
		api.postTokenRequest({ (url: URL!, token: String!) -> () in
			if let loginHelper = self.loginHelper {
				loginHelper.client(self, encounteredOAuthURL: url)

				self._sessions[token] = api
			} else {
				print("no login helper")
			}
        }, authenticateInsteadOfAuthorize: false, forceLogin: true, screenName: nil, oauthCallback: "canoe://callback") { error in
            print("1. fetching oauth token: ", error)
        }
	}
}

extension Twitter: OAuthClient {
	public func handleLoginResponse(_ response: [String: Any]) {
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

		api.postAccessTokenRequest(withPIN: verifier, successBlock: { (oauthToken: String!, oauthTokenSecret: String!, userID: String!, username: String!) -> () in
			var accountsString = self.keychain.passwordForServer(loggedInAccounts, area: "app") ?? ""
			if !accountsString.components(separatedBy: ",").contains(username) {
				accountsString += username + ","

				self.keychain.setPassword(accountsString, forServer: loggedInAccounts, area: "app", displayValue: loggedInAccounts)
			}

			self.keychain.setPassword(oauthToken, forServer: username, area: oauthTokenKeychainIdentifier, displayValue: username + oauthTokenKeychainIdentifier)
			self.keychain.setPassword(oauthTokenSecret, forServer: username, area: oauthTokenSecretKeychainIdentifier, displayValue: username + oauthTokenSecretKeychainIdentifier)

			self._sessions[username] = self._sessions.removeValue(forKey: oauthToken)

			api.verify(username)

			if let loginHelper = self.loginHelper {
				loginHelper.client(self, completedLoginAttempt: true, forSession: api)
			}
		}, errorBlock: { error in
			print("2. fetching oauth secret", error)

			if let loginHelper = self.loginHelper {
				loginHelper.client(self, completedLoginAttempt: false, forSession: api)
			}
		})
	}
}

// MARK: -

extension STTwitterAPI: Session {
	internal func verify(_ account: String) {
		userName = account

		verifyCredentials(userSuccessBlock: { (_, _) -> () in
		}, errorBlock: { (error) -> () in
			print(self, error)
		})
	}
	public func fetch(_ feed: FeedType, since: String?, handler: FetchResponse?) {
		switch(feed) {
		case .home: fetchHomeFeed(since, handler: handler)
		case .userActivity: fetchUserActivityFeed(since, handler: handler)
		case .personalMessages:
			// WARNING: should probably have a barrier and only call handler once when both calls finish
			fetchUserReceivedPersonalMessagesFeed(since, handler: handler)
			fetchUserSentPersonalMessagesFeed(since, handler: handler)
		}
	}

	public func reportSpam(_ person: Person) {
		postUsersReportSpam(forScreenName: person.username, orUserID: person.id, successBlock: { (_) -> () in
			}, errorBlock: { (_) -> () in
		})
	}

	public func block(_ person: Person) {
		postBlocksCreate(withScreenName: person.username, orUserID: person.id, includeEntities: true, skipStatus: true, successBlock: { (_) -> () in
		}, errorBlock: { (_) -> () in
		})
	}

	public func remove(_ item: Item, feed: FeedType) {
		if feed == .personalMessages {
			postDestroyDirectMessage(withID: item.id, includeEntities: true, successBlock: { (_) -> () in
			}, errorBlock: { (_) -> () in
			})
		}
	}

	public func post(_ feed: FeedType, message: String, to person: Person) {
		if feed == .personalMessages {
			postDirectMessage(message, forScreenName: person.username, orUserID: person.id, successBlock: { (_) -> () in
			}, errorBlock: { (_) -> () in
			})
		}
	}


	func fetchHomeFeed(_ since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		getHomeTimeline(sinceID: since, count: limit, successBlock: { (activity) -> () in
			let items = activity.map({ return Item(dictionary: $0 as! [String: Any]) })
			if let handler = handler { handler(items, nil) }
		}) { error in
			if let handler = handler { handler(nil, error) }
			print("unable to fetch home feed", error)
		}
	}

	func fetchUserActivityFeed(_ since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		getMentionsTimeline(sinceID: since, count: limit, successBlock: { (activity) -> () in
			let items = activity.map({ return Item(dictionary: $0 as! [String: Any]) })
			if let handler = handler { handler(items, nil) }
		}) { error in
			if let handler = handler { handler(nil, error) }
			print("unable to fetch activity feed", error)
		}
	}

	func fetchUserReceivedPersonalMessagesFeed(_ since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		getDirectMessages(sinceID: since, count: limit, successBlock: { (mentions) -> () in
			let items = mentions.map({ return Item(dictionary: $0 as! [String: Any]) })
			if let handler = handler { handler(items, nil) }
		}) { error in
			if let handler = handler { handler(nil, error) }
			print("unable to direct mentions", error)
		}
	}

	func fetchUserSentPersonalMessagesFeed(_ since: String? = nil, limit: UInt = 200, handler: FetchResponse?) {
		getDirectMessages(sinceID: since, maxID: nil, count: String(limit), fullText: true, page: nil, includeEntities: true, successBlock: { (mentions) -> () in
			let items = mentions.map({ return Item(dictionary: $0 as! [String: Any]) })
			if let handler = handler { handler(items, nil) }
		}) { (error) -> () in
			if let handler = handler { handler(nil, error) }
			print("unable to direct mentions", error)
		}
	}

	public var title: String {
        return userName
	}

	public var username: String {
        return userName
	}
}
