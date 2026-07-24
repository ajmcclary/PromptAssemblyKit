import Foundation

/// Pure prompt-packaging policy (PromptViewModel decomposition, Slice 3,
/// 2026-07-16): merges a copy preset with per-workspace Manual customizations
/// and current UI defaults into a `PromptContextResolved`. Hoisted from
/// PromptViewModel so the resolution matrix is testable without the app.
/// PromptViewModel keeps name-stable wrappers that supply `UIDefaults`.
public enum PromptContextResolver {
	/// The current UI fallbacks the resolver merges against. The app maps its
	/// git UI mode (GitDiffInclusionMode) to `GitInclusion` at the boundary.
	public struct UIDefaults {
		public var xmlCopyPromptFormat: ApplyPromptFormat
		public var fileTreeOption: FileTreeOption
		public var codeMapUsage: CodeMapUsage
		public var gitInclusion: GitInclusion
		public var codeMapsGloballyDisabled: Bool

		public init(
			xmlCopyPromptFormat: ApplyPromptFormat,
			fileTreeOption: FileTreeOption,
			codeMapUsage: CodeMapUsage,
			gitInclusion: GitInclusion,
			codeMapsGloballyDisabled: Bool
		) {
			self.xmlCopyPromptFormat = xmlCopyPromptFormat
			self.fileTreeOption = fileTreeOption
			self.codeMapUsage = codeMapUsage
			self.gitInclusion = gitInclusion
			self.codeMapsGloballyDisabled = codeMapsGloballyDisabled
		}
	}

	public static func resolveCopyCodeMapUsage(
		isManualPreset: Bool,
		customCodeMapUsage: CodeMapUsage?,
		presetCodeMapUsage: CodeMapUsage?,
		uiCodeMapUsage: CodeMapUsage,
		globallyDisabled: Bool = false
	) -> CodeMapUsage {
		guard !globallyDisabled else { return .none }
		if isManualPreset {
			return uiCodeMapUsage
		}
		return presetCodeMapUsage ?? uiCodeMapUsage
	}

	public static func mapGitInclusion(
		custom: GitInclusion?,
		preset: GitInclusion?,
		uiFallback: GitInclusion,
		isManualPreset: Bool
	) -> GitInclusion {
		if let c = custom { return c }
		if let p = preset { return p }
		if isManualPreset {
			return uiFallback
		}
		return .none
	}

	/// Central resolver that merges a preset with working customizations and
	/// current UI defaults. Manual preset is the only place where per-workspace
	/// overrides apply.
	public static func resolve(
		preset: CopyPreset,
		custom: CopyCustomizations?,
		ui: UIDefaults
	) -> PromptContextResolved {
		let isManualPreset = (preset.builtInKind == .manual) || (preset.id == BuiltInCopyPresets.manual.id)
		let effectiveCustom = isManualPreset ? custom : nil

		var xmlFormat = effectiveCustom?.xmlFormat ?? preset.xmlFormat
		let desiredSystemPromptFlavor = effectiveCustom?.systemPromptFlavor ?? preset.systemPromptFlavor

		// If a preset carries a code-edit system flavor but no explicit XML
		// format (e.g., "Manual (XML)"), adopt the user's current XML
		// clipboard preference so we produce the XML-structured clipboard and
		// keep edit prompts out of meta.
		if xmlFormat == nil, let flavor = preset.systemPromptFlavor {
			switch flavor {
			case .codeEditDiff, .codeEditWhole:
				// Honor the Diff view's XML copy setting (Diff/Whole/Architect)
				xmlFormat = ui.xmlCopyPromptFormat
			default:
				break
			}
		}

		// Merge include flags (force to true since UI elements were removed)
		let includeFiles       = (effectiveCustom?.includeFiles       ?? preset.includeFiles)       ?? true
		let includeUserPrompt  = (effectiveCustom?.includeUserPrompt  ?? preset.includeUserPrompt)  ?? true
		let includeMetaPrompts = (effectiveCustom?.includeMetaPrompts ?? preset.includeMetaPrompts) ?? true
		let includeFileTree    = (effectiveCustom?.includeFileTree    ?? preset.includeFileTree)    ?? true

		// File-tree and code-map behaviour (fallback to current UI)
		let desiredFileTreeMode = effectiveCustom?.fileTreeMode ?? preset.fileTreeMode ?? ui.fileTreeOption

		let desiredCodeMapUsage = resolveCopyCodeMapUsage(
			isManualPreset: isManualPreset,
			customCodeMapUsage: effectiveCustom?.codeMapUsage,
			presetCodeMapUsage: preset.codeMapUsage,
			uiCodeMapUsage: ui.codeMapUsage,
			globallyDisabled: ui.codeMapsGloballyDisabled
		)

		let desiredGitInclusion = mapGitInclusion(
			custom: effectiveCustom?.gitInclusion,
			preset: preset.gitInclusion,
			uiFallback: ui.gitInclusion,
			isManualPreset: isManualPreset
		)

		// MCP metadata: explicit override > preset setting > infer from MCP system prompt flavors
		let desiredIncludeMCPMetadata: Bool = {
			if let explicit = effectiveCustom?.includeMCPMetadata ?? preset.includeMCPMetadata {
				return explicit
			}
			// Default to true for MCP system prompt flavors
			if let flavor = desiredSystemPromptFlavor {
				switch flavor {
				case .mcpAgent, .mcpPairProgram, .mcpDiscover:
					return true
				default:
					return false
				}
			}
			return false
		}()

		return PromptContextResolved(
			includeFiles: includeFiles,
			includeUserPrompt: includeUserPrompt,
			includeMetaPrompts: includeMetaPrompts,
			includeFileTree: includeFileTree,
			xmlFormat: xmlFormat,
			fileTreeMode: desiredFileTreeMode,
			codeMapUsage: desiredCodeMapUsage,
			gitInclusion: desiredGitInclusion,
			systemPromptFlavor: desiredSystemPromptFlavor,
			storedPromptIds: preset.storedPromptIds,
			includeMCPMetadata: desiredIncludeMCPMetadata
		)
	}

	public static func applyingGlobalCodeMapOverride(
		_ cfg: PromptContextResolved,
		globallyDisabled: Bool
	) -> PromptContextResolved {
		guard globallyDisabled else { return cfg }
		var copy = cfg
		copy.codeMapUsage = .none
		return copy
	}

	/// Returns a copy of `cfg` with `codeMapUsage` overridden when provided.
	/// Used by context builder to normalize selection to `.auto` mode without
	/// affecting the user's preset.
	public static func withCodeMapUsageOverride(
		_ cfg: PromptContextResolved,
		override: CodeMapUsage?,
		globallyDisabled: Bool
	) -> PromptContextResolved {
		var copy = cfg
		if globallyDisabled {
			copy.codeMapUsage = .none
			return copy
		}
		guard let override else { return copy }
		copy.codeMapUsage = override
		return copy
	}
}
