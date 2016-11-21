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
	func avatar(_ person: Person, completion: @escaping () -> ()) -> AvatarType?
}

public class AvatarController: AvatarProvider {
    fileprivate var cache = [String: AvatarType]()
	fileprivate lazy var fetching = Set<URL>()

	public required init() {}

	public func avatar(_ person: Person, completion: @escaping () -> ()) -> AvatarType? {
		if let avatar = avatarFromMemory(person) {
			return avatar
		}

		if let avatar = avatarFromDisk(person) {
            cache[person.avatar.lastPathComponent] = avatar
			return avatar
		}

		if fetching.contains(person.avatar) {
			return nil
		}

		fetching.insert(person.avatar)

		URLSession.shared.dataTask(with: person.avatar, completionHandler: { [weak self] (data, response, error) -> () in
			guard let this = self else { return }

			this.fetching.remove(person.avatar)

			if let data = data, data.count > 0 {
				this.saveAvatar(data, forPerson: person)

				DispatchQueue.main.async(execute: completion)
			}
		}).resume()

		return nil
	}

	fileprivate func avatarFromMemory(_ person: Person) -> AvatarType? {
        return cache[person.avatar.lastPathComponent]
	}

	fileprivate func avatarFromDisk(_ person: Person) -> AvatarType? {
		guard let avatarPath = localPath(person) else {
			return nil
		}

		guard let avatarData = try? Data(contentsOf: avatarPath) else {
			return nil
		}

		guard let avatar = AvatarType(data: avatarData) else {
			return nil
		}

		return avatar
	}

	fileprivate func saveAvatar(_ data: Data, forPerson person: Person) {
		let fileManger = FileManager()
		let avatarCacheDirectory = cacheDirectory()!
		if !fileManger.fileExists(atPath: avatarCacheDirectory.absoluteString) {
			let _ = try? fileManger.createDirectory(at: avatarCacheDirectory, withIntermediateDirectories: true, attributes: nil)
		}

		if let path = localPath(person) {
			try? data.write(to: path, options: [.atomic])
		}
	}

	fileprivate func cacheDirectory() -> URL? {
		guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
			return nil
		}

		return URL(fileURLWithPath: cacheDirectory).appendingPathComponent("Avatars")
	}

	fileprivate func localPath(_ person: Person) -> URL? {
		guard let avatarDirectory = cacheDirectory() else {
			return nil
		}

		let key = person.avatar.lastPathComponent

		return avatarDirectory.appendingPathComponent(key)
	}
}
