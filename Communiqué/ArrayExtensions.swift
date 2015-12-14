extension Array where Element: Equatable {
	func unique() -> [Element] {
		var values = [Element]()

		forEach {
			if !values.contains($0) {
				values.append($0)
			}
		}

		return values
	}
}
