import XCTest
import PromptAssemblyKit

/// Public-API boundary contract for PromptAssemblyKit (the second migrate.md
/// extraction). The deep behavior pins live in the four suites that moved
/// with the code; this file pins two things those suites cannot: (1) every
/// vocabulary family RepoPrompt consumes stays PUBLIC — this file
/// deliberately imports WITHOUT `@testable`, so any accidental
/// de-publicizing breaks compilation — and (2) the raw-value, coding-key,
/// and stable-UUID formats that cross the package boundary as persisted
/// identity (UserDefaults section order, SavedPrompts.json, preset
/// migration IDs).
final class PromptAssemblyKitPublicAPIContractTests: XCTestCase {
	// Compile-time public-visibility pins, one alias per vocabulary family.
	// A tuple type references each member type without needing constructible
	// values; removal or de-publicizing of any member is a compile error.
	private typealias AssemblyFamily = (PromptSection, PromptAssemblyBuilder)
	private typealias PresetFamily = (CopyPreset, CopyPresetKind, CopyCustomizations, CopyPresetOverrides, PromptContextResolved)
	private typealias VocabularyFamily = (FileTreeOption, CodeMapUsage, GitInclusion, ApplyPromptFormat, SystemPromptFlavor)
	private typealias LibraryFamily = (StoredPrompt, PromptExport)

	// MARK: - Persisted raw-value identity

	func testPromptSectionPersistedIdentityIsPinned() {
		XCTAssertEqual(
			PromptSection.allCases.map(\.rawValue),
			["fileMap", "fileContents", "metaPrompts", "diffFormatting", "userInstructions", "gitDiff"]
		)
		XCTAssertEqual(
			PromptAssemblyBuilder.defaultSectionOrder,
			[.fileMap, .fileContents, .gitDiff, .diffFormatting, .metaPrompts, .userInstructions]
		)
	}

	func testVocabularyRawValuesArePinned() {
		XCTAssertEqual(FileTreeOption.allCases.map(\.rawValue), ["Auto", "Full", "Selected", "None"])
		XCTAssertEqual(CodeMapUsage.allCases.map(\.rawValue), ["auto", "complete", "selected", "none"])
		XCTAssertEqual(GitInclusion.allCases.map(\.rawValue), ["none", "selected", "complete"])
		XCTAssertEqual(ApplyPromptFormat.allCases.map(\.rawValue), ["Diff", "Whole", "Architect"])
		XCTAssertEqual(CopyPresetKind.allCases.map(\.rawValue), [
			"standard", "plan", "manual", "editXML", "proEdit",
			"diffFollowUp", "codeReview", "mcpAgent", "mcpPair", "mcpPlan", "mcpBuilder"
		])
	}

	// MARK: - Built-in preset stable identity (migration contract)

	func testBuiltInPresetStableUUIDsArePinned() throws {
		XCTAssertEqual(BuiltInCopyPresets.standard.id, try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000000")))
		XCTAssertEqual(BuiltInCopyPresets.manual.id, try XCTUnwrap(UUID(uuidString: "22222222-2222-2222-2222-222222222222")))
		XCTAssertEqual(BuiltInCopyPresets.all.count, 11)
		XCTAssertEqual(BuiltInCopyPresets.preset(for: .manual)?.id, BuiltInCopyPresets.manual.id)
		XCTAssertEqual(BuiltInCopyPresets.preset(with: BuiltInCopyPresets.standard.id)?.builtInKind, .standard)
	}

	// MARK: - Persisted coding-key identity through the public API

	func testStoredPromptEncodedKeySetThroughPublicAPI() throws {
		let prompt = StoredPrompt(
			id: try XCTUnwrap(UUID(uuidString: "8E81AAC2-79CE-4897-A59E-EFD81EEBB7E9")),
			title: "T", content: "C", isUserEdited: true
		)
		let data = try PromptLibraryCodec.encodeLibrary([prompt])
		let objects = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
		XCTAssertEqual(objects.count, 1)
		XCTAssertEqual(Set(objects[0].keys), ["id", "title", "content", "isUserEdited"])
	}

	// MARK: - Behavior reachable without @testable

	func testBuilderAssemblesThroughPublicAPI() {
		let out = PromptAssemblyBuilder.build(
			order: [.fileMap, .userInstructions],
			disabled: [],
			duplicateUserInstructionsAtTop: false,
			snippets: [.fileMap: "TREE", .userInstructions: "GO"]
		)
		XCTAssertEqual(out, "TREE\nGO\n")
	}

	func testResolverAndOverridesReachableThroughPublicAPI() {
		let resolved = PromptContextResolver.resolve(
			preset: BuiltInCopyPresets.manual,
			custom: CopyCustomizations(fileTreeMode: .selected),
			ui: PromptContextResolver.UIDefaults(
				xmlCopyPromptFormat: .diff,
				fileTreeOption: .auto,
				codeMapUsage: .auto,
				gitInclusion: .selected,
				codeMapsGloballyDisabled: false
			)
		)
		XCTAssertEqual(resolved.fileTreeMode, .selected)
		XCTAssertTrue(resolved.rendersFileTree)
		XCTAssertTrue(CopyPresetOverrides.empty(for: BuiltInCopyPresets.manual.id).isEmpty)
		XCTAssertNil(GitInclusion.fromMCPScope("bogus"))
	}
}
