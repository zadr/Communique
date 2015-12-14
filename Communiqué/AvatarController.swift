// WARNING: this should probably be atomic-y and more resiliant to multiple controllers existing at once, but current architecture means that doesn't matter yet

#if os(iOS)
	import UIKit
	public typealias AvatarType = UIImage
#else
	import AppKit
	public typealias AvatarType = NSImage
#endif

public protocol AvatarProvider {
	init()
	func avatar(person: Person, completion: () -> Void) -> AvatarType?
}

public class AvatarController: AvatarProvider {
	private lazy var cache = NSCache()
	private lazy var fetching = Set<NSURL>()

	public required init() {}

	public func avatar(person: Person, completion: () -> Void) -> AvatarType? {
		if let avatar = avatarFromMemory(person) {
			return avatar
		}

		if let avatar = avatarFromDisk(person) {
			return avatar
		}

		if fetching.contains(person.avatar) {
			return nil
		}

		fetching.insert(person.avatar)

		NSURLSession.sharedSession().dataTaskWithURL(person.avatar, completionHandler: { [weak self] (data, response, error) -> Void in
			guard let this = self else { return }

			this.fetching.remove(person.avatar)

			if let data = data where data.length > 0 {
				this.saveAvatar(data, forPerson: person)

				dispatch_async(dispatch_get_main_queue(), completion)
			}
		}).resume()

		return nil
	}

	private func avatarFromMemory(person: Person) -> AvatarType? {
		return cache.objectForKey(person.avatar.lastPathComponent!) as? AvatarType
	}

	private func avatarFromDisk(person: Person) -> AvatarType? {
		guard let avatarPath = localPath(person) else {
			return nil
		}

		guard let avatarData = NSData(contentsOfURL: avatarPath) else {
			return nil
		}

		guard let avatar = AvatarType(data: avatarData) else {
			return nil
		}

		cache.setObject(avatar, forKey: person.avatar.lastPathComponent!, cost: avatarData.length)

		return avatar
	}

	private func saveAvatar(data: NSData, forPerson person: Person) {
		let fileManger = NSFileManager()
		let avatarCacheDirectory = cacheDirectory()!
		if !fileManger.fileExistsAtPath(avatarCacheDirectory.absoluteString) {
			let _ = try? fileManger.createDirectoryAtURL(avatarCacheDirectory, withIntermediateDirectories: true, attributes: nil)
		}

		if let path = localPath(person) {
			data.writeToURL(path, atomically: true)
		}
	}

	private func cacheDirectory() -> NSURL? {
		guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
			return nil
		}

		return NSURL(fileURLWithPath: cacheDirectory).URLByAppendingPathComponent("Avatars")
	}

	private func localPath(person: Person) -> NSURL? {
		guard let avatarDirectory = cacheDirectory() else {
			return nil
		}

		guard let key = person.avatar.lastPathComponent else {
			return nil
		}

		return avatarDirectory.URLByAppendingPathComponent(key)
	}
}
