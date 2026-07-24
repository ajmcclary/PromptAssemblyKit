import XCTest
@testable import PromptAssemblyKit

/// Pins StoredPrompt's persistence contract (prompt-library decomposition).
/// These are characterization tests: if one fails after a change, you changed
/// observable persistence behavior — either revert or consciously migrate.
final class StoredPromptContractTests: XCTestCase {
	private let id = UUID(uuidString: "8E81AAC2-79CE-4897-A59E-EFD81EEBB7E9")!

	// MARK: - Decoding

	func testMissingIsUserEditedDecodesAsFalse() throws {
		let json = """
		{"id": "\(id.uuidString)", "title": "T", "content": "C"}
		"""
		let prompt = try JSONDecoder().decode(StoredPrompt.self, from: Data(json.utf8))
		XCTAssertEqual(prompt.id, id)
		XCTAssertEqual(prompt.title, "T")
		XCTAssertEqual(prompt.content, "C")
		XCTAssertFalse(prompt.isUserEdited)
	}

	func testPresentIsUserEditedDecodesAsGiven() throws {
		let json = """
		{"id": "\(id.uuidString)", "title": "T", "content": "C", "isUserEdited": true}
		"""
		let prompt = try JSONDecoder().decode(StoredPrompt.self, from: Data(json.utf8))
		XCTAssertTrue(prompt.isUserEdited)
	}

	// MARK: - Coding keys

	func testEncodedKeySetIsStable() throws {
		let prompt = StoredPrompt(id: id, title: "T", content: "C", isUserEdited: true)
		let data = try JSONEncoder().encode(prompt)
		let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
		XCTAssertEqual(Set(object.keys), ["id", "title", "content", "isUserEdited"])
		XCTAssertEqual(object["id"] as? String, id.uuidString)
		XCTAssertEqual(object["title"] as? String, "T")
		XCTAssertEqual(object["content"] as? String, "C")
		XCTAssertEqual(object["isUserEdited"] as? Bool, true)
	}

	func testRoundTripPreservesAllFields() throws {
		let prompt = StoredPrompt(id: id, title: "T", content: "C", isUserEdited: true)
		let decoded = try JSONDecoder().decode(StoredPrompt.self, from: JSONEncoder().encode(prompt))
		XCTAssertEqual(decoded.id, prompt.id)
		XCTAssertEqual(decoded.title, prompt.title)
		XCTAssertEqual(decoded.content, prompt.content)
		XCTAssertTrue(decoded.isUserEdited)
	}

	// MARK: - Equality (deliberately ignores isUserEdited)

	func testEqualityIgnoresIsUserEdited() {
		let a = StoredPrompt(id: id, title: "T", content: "C", isUserEdited: false)
		let b = StoredPrompt(id: id, title: "T", content: "C", isUserEdited: true)
		XCTAssertEqual(a, b)
	}

	func testEqualityRespectsIdentityAndVisibleContent() {
		let a = StoredPrompt(id: id, title: "T", content: "C")
		XCTAssertNotEqual(a, StoredPrompt(id: UUID(), title: "T", content: "C"))
		XCTAssertNotEqual(a, StoredPrompt(id: id, title: "T2", content: "C"))
		XCTAssertNotEqual(a, StoredPrompt(id: id, title: "T", content: "C2"))
	}
}
