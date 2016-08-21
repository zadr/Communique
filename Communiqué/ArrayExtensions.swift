extension Array where Element: Equatable {
	func unique() -> [Element] {
        return reduce([Element]()) {
            if !$0.contains($1) { return $0 + [$1] }
            return $0
        }
	}
}
