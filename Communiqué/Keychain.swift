import Security

protocol KeychainEssentials {
	func setPassword(_ password: String, forServer server: String, area: String?, displayValue: String?)
	func passwordForServer(_ server: String, area: String?) -> String?
	func removePasswordForServer(_ server: String, area: String?)
}

public class Keychain: KeychainEssentials {
	private func keychainDictionary(_ server: String, account: String?) -> [String: AnyObject] {
		var dictionary = [String: AnyObject]()
		dictionary[String(kSecClass)] = String(kSecClassInternetPassword)
		dictionary[String(kSecAttrServer)] = server

		if let account = account {
			dictionary[String(kSecAttrAccount)] = account
		}

		return dictionary
	}

	// MARK: -

	func setPassword(_ password: String, forServer server: String, area: String? = nil, displayValue: String? = nil) {
		var entry = keychainDictionary(server, account: area)
		if let displayValue = displayValue, displayValue.utf8.count > 0 {
			entry[String(kSecAttrLabel)] = displayValue
		}

		if let asData = password.data(using: String.Encoding.utf8) {
			entry[String(kSecValueData)] = asData
		}

		let status = SecItemAdd(entry as NSDictionary, nil)
		if status == errSecDuplicateItem {
			let update: [String: AnyObject] = [String(kSecValueData): entry[String(kSecValueData)]!]

			entry.removeValue(forKey: String(kSecValueData))

			SecItemUpdate(entry as NSDictionary, update as NSDictionary)
		}
	}

	func passwordForServer(_ server: String, area: String? = nil) -> String? {
		var entry = keychainDictionary(server, account:  area)
		entry[String(kSecReturnData)] = kCFBooleanTrue
		entry[String(kSecMatchLimit)] = String(kSecMatchLimitOne)

		var data: CFTypeRef?
		let status = SecItemCopyMatching(entry as NSDictionary, &data)

		if let data = data, status == noErr {
			return NSString(data: data as! Data, encoding: String.Encoding.utf8.rawValue) as? String
		}

		return nil
	}

	func removePasswordForServer(_ server: String, area: String? = nil) {
		SecItemDelete(keychainDictionary(server, account: area) as NSDictionary)
	}
}
