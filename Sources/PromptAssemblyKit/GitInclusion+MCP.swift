import Foundation

public extension GitInclusion {
	public static func fromMCPScope(_ raw: String?) -> GitInclusion? {
		guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
			!raw.isEmpty else { return nil }
		switch raw.lowercased() {
		case "none":
			return GitInclusion.none
		case "selected":
			return .selected
		case "all":
			return .complete
		default:
			return nil
		}
	}
}
