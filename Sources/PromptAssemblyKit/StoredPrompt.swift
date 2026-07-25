import Foundation

/// A saved prompt in the user's prompt library.
///
/// Hoisted from `PromptViewModel.StoredPrompt` (prompt-library decomposition,
/// 2026-07-16). Persistence contract — pinned by StoredPromptContractTests:
/// - Coding keys are exactly `id`, `title`, `content`, `isUserEdited` and must
///   not change (SavedPrompts.json + legacy UserDefaults payloads).
/// - A payload missing `isUserEdited` decodes as `false` (files written before
///   the flag existed).
/// - Equality deliberately IGNORES `isUserEdited`: built-in upgrade and reset
///   flows compare identity + visible content only.
public struct StoredPrompt: Identifiable, Codable, Equatable, Sendable {
	public let id: UUID
	public var title: String
	public var content: String
	/// Tracks whether the user has manually edited a built-in prompt.
	/// When true, auto-upgrades of built-in content are skipped.
	public var isUserEdited: Bool

	private enum CodingKeys: String, CodingKey {
		case id
		case title
		case content
		case isUserEdited
	}

	public init(id: UUID, title: String, content: String, isUserEdited: Bool = false) {
		self.id = id
		self.title = title
		self.content = content
		self.isUserEdited = isUserEdited
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		title = try container.decode(String.self, forKey: .title)
		content = try container.decode(String.self, forKey: .content)
		isUserEdited = try container.decodeIfPresent(Bool.self, forKey: .isUserEdited) ?? false
	}

	public static func == (lhs: StoredPrompt, rhs: StoredPrompt) -> Bool {
		return lhs.id == rhs.id &&
			lhs.title == rhs.title &&
			lhs.content == rhs.content
	}
}
