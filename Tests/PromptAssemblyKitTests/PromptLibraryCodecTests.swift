import XCTest
@testable import PromptAssemblyKit

final class PromptLibraryCodecTests: XCTestCase {
	// MARK: - Library codec

	func testLibraryRoundTrip() throws {
		let prompts = [
			StoredPrompt(id: UUID(), title: "A", content: "one"),
			StoredPrompt(id: UUID(), title: "B", content: "two", isUserEdited: true)
		]
		let decoded = try PromptLibraryCodec.decodeLibrary(PromptLibraryCodec.encodeLibrary(prompts))
		XCTAssertEqual(decoded, prompts)
		XCTAssertTrue(decoded[1].isUserEdited)
	}

	// MARK: - Export codec

	func testEncodeExportsDropsIDAndEditFlag() throws {
		let prompts = [StoredPrompt(id: UUID(), title: "A", content: "one", isUserEdited: true)]
		let data = try PromptLibraryCodec.encodeExports(prompts)
		let objects = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
		XCTAssertEqual(objects.count, 1)
		XCTAssertEqual(Set(objects[0].keys), ["title", "content"])

		let exports = try PromptLibraryCodec.decodeExports(data)
		XCTAssertEqual(exports, [PromptExport(title: "A", content: "one")])
	}

	// MARK: - Merge policy

	func testMergeSkipsTitleContentDuplicatesAndAssignsFreshIDs() {
		let existing = StoredPrompt(id: UUID(), title: "A", content: "one")
		let freshID = UUID()
		let (merged, addedCount) = PromptLibraryCodec.mergeExternalPrompts(
			current: [existing],
			external: [
				PromptExport(title: "A", content: "one"),   // duplicate → skipped
				PromptExport(title: "A", content: "two"),   // same title, new content → added
				PromptExport(title: "B", content: "one")    // new title → added
			],
			makeID: { freshID }
		)
		XCTAssertEqual(addedCount, 2)
		XCTAssertEqual(merged.count, 3)
		XCTAssertEqual(merged[0], existing)
		XCTAssertEqual(merged[1].id, freshID)
		XCTAssertFalse(merged[1].isUserEdited)
		XCTAssertEqual(merged[2].title, "B")
	}

	func testMergeDetectsDuplicatesWithinExternalBatch() {
		let (merged, addedCount) = PromptLibraryCodec.mergeExternalPrompts(
			current: [],
			external: [
				PromptExport(title: "A", content: "one"),
				PromptExport(title: "A", content: "one")
			]
		)
		XCTAssertEqual(addedCount, 1)
		XCTAssertEqual(merged.count, 1)
	}
}
