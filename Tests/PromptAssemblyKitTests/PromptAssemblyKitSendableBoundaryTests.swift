import XCTest
import PromptAssemblyKit

/// Concurrency boundary contract for PromptAssemblyKit (Swift 6 language mode
/// migration). The package is a pure vocabulary of Foundation value types, so
/// the migration added exactly one thing to the public surface: `Sendable`
/// conformance on every family RepoPrompt consumes. That conformance is what
/// lets `BuiltInCopyPresets`' `static let` constants remain plain globals
/// under full data-race checking instead of needing an isolation annotation
/// or `nonisolated(unsafe)`.
///
/// This file pins that boundary two ways: a compile-time proof that each
/// public type still conforms, and a runtime exercise of the cross-isolation
/// path — the built-in presets read and resolved concurrently from many
/// domains at once, plus a preset round-tripped through an actor. Imported
/// WITHOUT `@testable`, matching the public-API contract suite: dropping a
/// `Sendable` conformance breaks compilation here.
final class PromptAssemblyKitSendableBoundaryTests: XCTestCase {
	// MARK: - Compile-time conformance pins

	/// Succeeds only if `T` conforms to `Sendable`; the constraint is the
	/// assertion, so each call below is a compile-time pin.
	private func pinSendable<T: Sendable>(_: T.Type) {}

	func testPublicValueTypesConformToSendable() {
		pinSendable(PromptSection.self)
		pinSendable(PromptAssemblyBuilder.self)

		pinSendable(CopyPreset.self)
		pinSendable(CopyPresetKind.self)
		pinSendable(CopyCustomizations.self)
		pinSendable(CopyPresetOverrides.self)
		pinSendable(PromptContextResolved.self)
		pinSendable(PromptContextResolver.UIDefaults.self)

		pinSendable(FileTreeOption.self)
		pinSendable(CodeMapUsage.self)
		pinSendable(GitInclusion.self)
		pinSendable(ApplyPromptFormat.self)
		pinSendable(SystemPromptFlavor.self)

		pinSendable(StoredPrompt.self)
		pinSendable(PromptExport.self)
	}

	// MARK: - Cross-isolation-domain exercise

	private static let probeDefaults = PromptContextResolver.UIDefaults(
		xmlCopyPromptFormat: .diff,
		fileTreeOption: .auto,
		codeMapUsage: .auto,
		gitInclusion: .selected,
		codeMapsGloballyDisabled: false
	)

	/// Reads the built-in preset globals and runs the resolver from 64
	/// concurrent tasks. Every task must observe the identical preset table
	/// and produce the identical resolution: the globals are immutable shared
	/// state, so concurrent readers cannot diverge.
	func testBuiltInPresetsResolveIdenticallyAcrossConcurrentDomains() async {
		let expected = Self.resolveAllPresetIdentities()

		let observations = await withTaskGroup(of: [String].self) { group in
			for _ in 0..<64 {
				group.addTask { Self.resolveAllPresetIdentities() }
			}
			var collected: [[String]] = []
			for await observation in group {
				collected.append(observation)
			}
			return collected
		}

		XCTAssertEqual(observations.count, 64)
		XCTAssertEqual(expected.count, BuiltInCopyPresets.all.count)
		for observation in observations {
			XCTAssertEqual(observation, expected)
		}
	}

	/// Sending a `CopyPreset` into an actor and reading it back must preserve
	/// value identity — the conformance is a real value-semantics claim, not
	/// just a compiler appeasement.
	func testPresetRoundTripsThroughActorUnchanged() async {
		let store = PresetStore()
		let original = BuiltInCopyPresets.mcpBuilder

		await store.store(original)
		let returned = await store.stored

		XCTAssertEqual(returned, original)
		XCTAssertEqual(returned?.id, BuiltInCopyPresets.mcpBuilder.id)
		XCTAssertEqual(returned?.builtInKind, .mcpBuilder)
	}

	/// A `PromptContextResolved` produced in one domain and consumed in
	/// another must carry its full resolution across unchanged.
	func testResolvedContextCrossesTaskBoundaryUnchanged() async {
		let local = Self.resolveManualWithGitOverride()

		// The type is spelled out rather than using `Self` deliberately: under
		// Apple Swift 6.4, `Task.detached { Self.staticMethod() }` inside a
		// CLASS crashes the region-based isolation checker ("pattern that the
		// region-based isolation checker does not understand how to check").
		// The explicit type name compiles cleanly and means the same thing
		// (this class is final). Do not "simplify" this back to `Self`.
		let task = Task.detached {
			PromptAssemblyKitSendableBoundaryTests.resolveManualWithGitOverride()
		}
		let remote = await task.value

		XCTAssertEqual(remote.fileTreeMode, local.fileTreeMode)
		XCTAssertEqual(remote.gitInclusion, local.gitInclusion)
		XCTAssertEqual(remote.codeMapUsage, local.codeMapUsage)
		XCTAssertEqual(remote.includeMCPMetadata, local.includeMCPMetadata)
		XCTAssertEqual(remote.rendersFileTree, local.rendersFileTree)
		XCTAssertEqual(remote.gitInclusion, .complete)
	}

	/// Resolves the Manual preset with a fixed customization. Pure, so it must
	/// produce the same value in every isolation domain that calls it.
	private static func resolveManualWithGitOverride() -> PromptContextResolved {
		PromptContextResolver.resolve(
			preset: BuiltInCopyPresets.manual,
			custom: CopyCustomizations(fileTreeMode: .selected, gitInclusion: .complete),
			ui: probeDefaults
		)
	}

	/// Stable, comparable digest of the whole built-in table resolved against
	/// one set of UI defaults. Pure: no shared mutable state of its own.
	private static func resolveAllPresetIdentities() -> [String] {
		BuiltInCopyPresets.all.map { preset in
			let resolved = PromptContextResolver.resolve(
				preset: preset,
				custom: nil,
				ui: probeDefaults
			)
			return [
				preset.id.uuidString,
				preset.name,
				preset.builtInKind?.rawValue ?? "-",
				resolved.fileTreeMode.rawValue,
				resolved.codeMapUsage.rawValue,
				resolved.gitInclusion.rawValue,
				resolved.xmlFormat?.rawValue ?? "-",
				resolved.systemPromptFlavor?.rawValue ?? "-",
				String(resolved.includeMCPMetadata)
			].joined(separator: "|")
		}
	}
}

/// Minimal actor used to prove `CopyPreset` genuinely crosses an isolation
/// boundary by value.
private actor PresetStore {
	private(set) var stored: CopyPreset?

	func store(_ preset: CopyPreset) {
		stored = preset
	}
}
