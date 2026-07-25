//
//  PromptAssemblyBuilder.swift
//  RepoPrompt
//
//  Created by Eric Provencher on 2025-04-16.
//

import Foundation

/// All blocks that can appear in the final prompt, in *logical* order.
/// The raw value is persisted in UserDefaults, so never rename casually.
public enum PromptSection: String, CaseIterable, Identifiable, Codable, Sendable {
	case fileMap, fileContents, metaPrompts, diffFormatting, userInstructions, gitDiff
	
	public var id: String { rawValue }
	public var displayName: String {
		switch self {
		case .fileMap:          return "File Tree"
		case .fileContents:     return "File Contents"
		case .gitDiff:          return "Git Diff"
		case .metaPrompts:      return "Meta Prompts"
		case .diffFormatting:   return "Diff Formatting"
		case .userInstructions: return "User Instructions"
		}
	}
}

/// Combines independently‑produced snippets in a caller‑supplied order.
public struct PromptAssemblyBuilder: Sendable {
    // Default order (2025-08): place Diff Formatting before Meta Prompts
    public static let defaultSectionOrder: [PromptSection] = [ .fileMap, .fileContents, .gitDiff, .diffFormatting, .metaPrompts, .userInstructions ]
	
	public let order: [PromptSection]
	public let disabled: Set<PromptSection>          // existing switches → pass in
	public let duplicateUserInstructionsAtTop: Bool  // new toggle
	public let snippets: [PromptSection : String]    // empty / missing → ignored
	
	public func build() -> String {
		var out = ""
		// optional first User Instructions block
		if duplicateUserInstructionsAtTop,
		let user = snippets[.userInstructions],
		user.isEmpty == false {
			out += user.hasSuffix("\n") ? user : (user + "\n")
		}
		
		for section in order where !disabled.contains(section) {
			guard let snip = snippets[section], snip.isEmpty == false else { continue }
			out += snip
			if !snip.hasSuffix("\n") { out += "\n" }
		}
		return out
	}
	
	/// Convenience static wrapper.
	public static func build(order: [PromptSection],
					  disabled: Set<PromptSection>,
					duplicateUserInstructionsAtTop: Bool,
					  snippets: [PromptSection : String]) -> String
	{
		PromptAssemblyBuilder(order: order,
							  disabled: disabled,
							duplicateUserInstructionsAtTop: duplicateUserInstructionsAtTop,
							  snippets: snippets).build()
	}
}
