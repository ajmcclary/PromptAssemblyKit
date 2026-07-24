import XCTest
@testable import PromptAssemblyKit

/// Pins the prompt-context resolution matrix hoisted from PromptViewModel
/// (Slice 3). Characterization tests: a failure means observable packaging
/// behavior changed.
final class PromptContextResolverTests: XCTestCase {
	private func ui(
		xml: ApplyPromptFormat = .diff,
		fileTree: FileTreeOption = .auto,
		codeMap: CodeMapUsage = .auto,
		git: GitInclusion = .selected,
		globallyDisabled: Bool = false
	) -> PromptContextResolver.UIDefaults {
		.init(
			xmlCopyPromptFormat: xml,
			fileTreeOption: fileTree,
			codeMapUsage: codeMap,
			gitInclusion: git,
			codeMapsGloballyDisabled: globallyDisabled
		)
	}

	// MARK: - resolveCopyCodeMapUsage matrix

	func testCodeMapUsageGlobalDisableWins() {
		XCTAssertEqual(
			PromptContextResolver.resolveCopyCodeMapUsage(
				isManualPreset: true, customCodeMapUsage: .complete,
				presetCodeMapUsage: .complete, uiCodeMapUsage: .complete,
				globallyDisabled: true
			),
			.none
		)
	}

	func testCodeMapUsageManualUsesUIRegardlessOfPreset() {
		XCTAssertEqual(
			PromptContextResolver.resolveCopyCodeMapUsage(
				isManualPreset: true, customCodeMapUsage: .complete,
				presetCodeMapUsage: .complete, uiCodeMapUsage: .none
			),
			.none
		)
	}

	func testCodeMapUsageNonManualPrefersPresetThenUI() {
		XCTAssertEqual(
			PromptContextResolver.resolveCopyCodeMapUsage(
				isManualPreset: false, customCodeMapUsage: nil,
				presetCodeMapUsage: .complete, uiCodeMapUsage: .none
			),
			.complete
		)
		XCTAssertEqual(
			PromptContextResolver.resolveCopyCodeMapUsage(
				isManualPreset: false, customCodeMapUsage: nil,
				presetCodeMapUsage: nil, uiCodeMapUsage: .auto
			),
			.auto
		)
	}

	// MARK: - mapGitInclusion

	func testGitInclusionPrecedenceCustomPresetManualFallback() {
		XCTAssertEqual(PromptContextResolver.mapGitInclusion(custom: .complete, preset: .none, uiFallback: .selected, isManualPreset: false), .complete)
		XCTAssertEqual(PromptContextResolver.mapGitInclusion(custom: nil, preset: .selected, uiFallback: .complete, isManualPreset: false), .selected)
		XCTAssertEqual(PromptContextResolver.mapGitInclusion(custom: nil, preset: nil, uiFallback: .complete, isManualPreset: true), .complete)
		XCTAssertEqual(PromptContextResolver.mapGitInclusion(custom: nil, preset: nil, uiFallback: .complete, isManualPreset: false), .none)
	}

	// MARK: - resolve: manual vs non-manual customizations

	func testCustomizationsApplyOnlyToManualPreset() {
		var custom = CopyCustomizations()
		custom.fileTreeMode = .files
		custom.codeMapUsage = .complete

		let nonManual = PromptContextResolver.resolve(
			preset: BuiltInCopyPresets.standard,
			custom: custom,
			ui: ui(fileTree: .auto, codeMap: .none)
		)
		// Non-manual presets ignore customizations entirely.
		XCTAssertEqual(nonManual.fileTreeMode, BuiltInCopyPresets.standard.fileTreeMode ?? .auto)

		let manual = PromptContextResolver.resolve(
			preset: BuiltInCopyPresets.manual,
			custom: custom,
			ui: ui(fileTree: .auto, codeMap: .none)
		)
		XCTAssertEqual(manual.fileTreeMode, .files)
		// Deliberate: Manual codeMapUsage always tracks the UI value; the
		// customization's codeMapUsage is never consulted (mirrors the
		// removingCodeMapUsageOverride() sanitization in manual snapshots).
		XCTAssertEqual(manual.codeMapUsage, .none)
	}

	func testIncludeFlagsDefaultTrue() {
		let resolved = PromptContextResolver.resolve(
			preset: BuiltInCopyPresets.manual,
			custom: nil,
			ui: ui()
		)
		XCTAssertTrue(resolved.includeFiles)
		XCTAssertTrue(resolved.includeUserPrompt)
		XCTAssertTrue(resolved.includeMetaPrompts)
		XCTAssertTrue(resolved.includeFileTree)
	}

	func testCodeEditFlavorWithoutXMLAdoptsUIXMLPreference() {
		var preset = BuiltInCopyPresets.standard
		preset.systemPromptFlavor = .codeEditDiff
		preset.xmlFormat = nil

		let resolved = PromptContextResolver.resolve(preset: preset, custom: nil, ui: ui(xml: .whole))
		XCTAssertEqual(resolved.xmlFormat, .whole)

		var nonEdit = BuiltInCopyPresets.standard
		nonEdit.systemPromptFlavor = .review
		nonEdit.xmlFormat = nil
		let reviewResolved = PromptContextResolver.resolve(preset: nonEdit, custom: nil, ui: ui(xml: .whole))
		XCTAssertNil(reviewResolved.xmlFormat)
	}

	func testMCPMetadataInferredFromMCPFlavors() {
		var mcp = BuiltInCopyPresets.standard
		mcp.systemPromptFlavor = .mcpAgent
		mcp.includeMCPMetadata = nil
		XCTAssertTrue(PromptContextResolver.resolve(preset: mcp, custom: nil, ui: ui()).includeMCPMetadata)

		var plain = BuiltInCopyPresets.standard
		plain.systemPromptFlavor = .review
		plain.includeMCPMetadata = nil
		XCTAssertFalse(PromptContextResolver.resolve(preset: plain, custom: nil, ui: ui()).includeMCPMetadata)

		var explicitOff = BuiltInCopyPresets.standard
		explicitOff.systemPromptFlavor = .mcpAgent
		explicitOff.includeMCPMetadata = false
		XCTAssertFalse(PromptContextResolver.resolve(preset: explicitOff, custom: nil, ui: ui()).includeMCPMetadata)
	}

	// MARK: - Global code-map override helpers

	func testApplyingGlobalCodeMapOverride() {
		let cfg = PromptContextResolver.resolve(preset: BuiltInCopyPresets.manual, custom: nil, ui: ui(codeMap: .complete))
		XCTAssertEqual(PromptContextResolver.applyingGlobalCodeMapOverride(cfg, globallyDisabled: false).codeMapUsage, .complete)
		XCTAssertEqual(PromptContextResolver.applyingGlobalCodeMapOverride(cfg, globallyDisabled: true).codeMapUsage, .none)
	}

	func testWithCodeMapUsageOverride() {
		let cfg = PromptContextResolver.resolve(preset: BuiltInCopyPresets.manual, custom: nil, ui: ui(codeMap: .complete))
		XCTAssertEqual(PromptContextResolver.withCodeMapUsageOverride(cfg, override: .auto, globallyDisabled: false).codeMapUsage, .auto)
		XCTAssertEqual(PromptContextResolver.withCodeMapUsageOverride(cfg, override: nil, globallyDisabled: false).codeMapUsage, .complete)
		XCTAssertEqual(PromptContextResolver.withCodeMapUsageOverride(cfg, override: .auto, globallyDisabled: true).codeMapUsage, .none)
	}
}
