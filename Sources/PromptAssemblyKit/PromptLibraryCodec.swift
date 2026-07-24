import Foundation

/// External structure used for importing and exporting prompts,
/// without relying on our internal UUID.
public struct PromptExport: Codable, Equatable {
	public let title: String
	public let content: String

	public init(title: String, content: String) {
		self.title = title
		self.content = content
	}
}

/// Pure prompt-library persistence policy (prompt-library decomposition,
/// 2026-07-16): JSON codec for the saved-prompts library and the
/// import/export DTOs, plus duplicate detection and merge policy.
/// Filesystem location, queueing, and I/O stay in the app's PromptStorage
/// adapter.
public enum PromptLibraryCodec {
	// MARK: - Library (SavedPrompts.json) codec

	public static func decodeLibrary(_ data: Data) throws -> [StoredPrompt] {
		try JSONDecoder().decode([StoredPrompt].self, from: data)
	}

	public static func encodeLibrary(_ prompts: [StoredPrompt]) throws -> Data {
		try JSONEncoder().encode(prompts)
	}

	// MARK: - Import/export DTO codec

	public static func decodeExports(_ data: Data) throws -> [PromptExport] {
		try JSONDecoder().decode([PromptExport].self, from: data)
	}

	/// Encode the internal `StoredPrompt` array as `PromptExport` DTOs.
	public static func encodeExports(_ prompts: [StoredPrompt]) throws -> Data {
		let exports = prompts.map { PromptExport(title: $0.title, content: $0.content) }
		return try JSONEncoder().encode(exports)
	}

	// MARK: - Merge policy

	/// Given the array of existing `StoredPrompt` and newly loaded external
	/// `PromptExport`, convert the external prompts into new `StoredPrompt`s,
	/// skipping duplicates. Returns a tuple: (merged array, count of new items).
	///
	/// Duplicates are checked by matching (title, content).
	/// If a prompt with the same title + content already exists, we skip adding
	/// a new one. Otherwise, create a new `StoredPrompt` with a fresh UUID.
	public static func mergeExternalPrompts(
		current: [StoredPrompt],
		external: [PromptExport],
		makeID: () -> UUID = UUID.init
	) -> (merged: [StoredPrompt], addedCount: Int) {
		var merged = current
		var addedCount = 0

		for item in external {
			// Check duplicates by (title, content)
			let duplicateExists = merged.contains(where: {
				$0.title == item.title && $0.content == item.content
			})

			if !duplicateExists {
				let newPrompt = StoredPrompt(
					id: makeID(),  // Always new ID
					title: item.title,
					content: item.content
				)
				merged.append(newPrompt)
				addedCount += 1
			}
		}
		return (merged, addedCount)
	}
}
