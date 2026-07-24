import XCTest
@testable import PromptAssemblyKit

/// Characterization tests pinning the assembly behavior the builder shipped
/// with when it moved out of the app (decomposition step 6).
final class PromptAssemblyBuilderTests: XCTestCase {
	func testBuildsInCallerSuppliedOrderSkippingDisabledAndEmpty() {
		let out = PromptAssemblyBuilder.build(
			order: [.userInstructions, .fileMap, .fileContents],
			disabled: [.fileMap],
			duplicateUserInstructionsAtTop: false,
			snippets: [
				.userInstructions: "do the thing",
				.fileMap: "TREE",
				.fileContents: "",
			]
		)
		XCTAssertEqual(out, "do the thing\n")
	}

	func testDuplicateUserInstructionsAtTopPrependsOnce() {
		let out = PromptAssemblyBuilder.build(
			order: [.fileMap, .userInstructions],
			disabled: [],
			duplicateUserInstructionsAtTop: true,
			snippets: [
				.fileMap: "TREE\n",
				.userInstructions: "instructions",
			]
		)
		XCTAssertEqual(out, "instructions\nTREE\ninstructions\n")
	}

	func testEachSnippetGainsTrailingNewlineOnlyWhenMissing() {
		let out = PromptAssemblyBuilder.build(
			order: [.fileMap, .fileContents],
			disabled: [],
			duplicateUserInstructionsAtTop: false,
			snippets: [.fileMap: "a\n", .fileContents: "b"]
		)
		XCTAssertEqual(out, "a\nb\n")
	}

	func testPromptSectionRawValuesArePinned() {
		// Persisted in UserDefaults — renaming a case is a data migration.
		XCTAssertEqual(
			PromptSection.allCases.map(\.rawValue),
			["fileMap", "fileContents", "metaPrompts", "diffFormatting", "userInstructions", "gitDiff"]
		)
		XCTAssertEqual(
			PromptAssemblyBuilder.defaultSectionOrder,
			[.fileMap, .fileContents, .gitDiff, .diffFormatting, .metaPrompts, .userInstructions]
		)
	}

	func testHoistedEnumRawValuesArePinned() {
		XCTAssertEqual(FileTreeOption.allCases.map(\.rawValue), ["Auto", "Full", "Selected", "None"])
		XCTAssertEqual(CodeMapUsage.allCases.map(\.rawValue), ["auto", "complete", "selected", "none"])
		XCTAssertEqual(ApplyPromptFormat.allCases.map(\.rawValue), ["Diff", "Whole", "Architect"])
		XCTAssertEqual(GitInclusion.allCases.map(\.rawValue), ["none", "selected", "complete"])
	}

	func testGitInclusionFromMCPScopeMapping() {
		XCTAssertEqual(GitInclusion.fromMCPScope("none"), GitInclusion.none)
		XCTAssertEqual(GitInclusion.fromMCPScope("SELECTED"), .selected)
		XCTAssertEqual(GitInclusion.fromMCPScope(" all "), .complete)
		XCTAssertNil(GitInclusion.fromMCPScope("bogus"))
		XCTAssertNil(GitInclusion.fromMCPScope(nil))
		XCTAssertNil(GitInclusion.fromMCPScope("  "))
	}

	func testCopyPresetCodableRoundTrip() throws {
		let overrides = CopyCustomizations(
			selectedPromptIDs: [UUID()],
			fileTreeMode: .selected,
			codeMapUsage: .complete,
			gitInclusion: .selected
		)
		let data = try JSONEncoder().encode(overrides)
		let decoded = try JSONDecoder().decode(CopyCustomizations.self, from: data)
		XCTAssertEqual(decoded, overrides)
	}
}
