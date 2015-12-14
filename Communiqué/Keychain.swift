import Security

protocol KeychainEssentials {
	func setPassword(password: String, forServer server: String, area: String?, displayValue: String?)
	func passwordForServer(server: String, area: String?) -> String?
	func removePasswordForServer(server: String, area: String?)
}

public class Keychain: KeychainEssentials {
	private func keychainDictionary(server: String, account: String?) -> [String: AnyObject] {
		var dictionary = [String: AnyObject]()
		dictionary[String(kSecClass)] = String(kSecClassInternetPassword)
		dictionary[String(kSecAttrServer)] = server

		if let account = account {
			dictionary[String(kSecAttrAccount)] = account
		}

		return dictionary
	}

	// MARK: -

	func setPassword(password: String, forServer server: String, area: String? = nil, displayValue: String? = nil) {
		var entry = keychainDictionary(server, account: area)
		if let displayValue = displayValue where displayValue.utf8.count > 0 {
			entry[String(kSecAttrLabel)] = displayValue
		}

		if let asData = password.dataUsingEncoding(NSUTF8StringEncoding) {
			entry[String(kSecValueData)] = asData
		}

		let status = SecItemAdd(entry as NSDictionary, nil)
		if status == errSecDuplicateItem {
			let update: [String: AnyObject] = [String(kSecValueData): entry[String(kSecValueData)]!]

			entry.removeValueForKey(String(kSecValueData))

			SecItemUpdate(entry as NSDictionary, update as NSDictionary)
		}
	}

	func passwordForServer(server: String, area: String? = nil) -> String? {
		var entry = keychainDictionary(server, account:  area)
		entry[String(kSecReturnData)] = kCFBooleanTrue
		entry[String(kSecMatchLimit)] = String(kSecMatchLimitOne)

		var data: CFTypeRef?
		let status = SecItemCopyMatching(entry as NSDictionary, &data)

		if let data = data where status == noErr {
			return NSString(data: data as! NSData, encoding: NSUTF8StringEncoding) as? String
		}

		return nil
	}

	func removePasswordForServer(server: String, area: String? = nil) {
		SecItemDelete(keychainDictionary(server, account: area) as NSDictionary)
	}
}
