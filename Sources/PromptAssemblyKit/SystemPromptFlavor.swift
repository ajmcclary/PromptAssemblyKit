import Foundation

// Hoisted verbatim out of SystemPromptService.swift (they were top-level
// enums there) — decomposition step 6. Raw values persist; never rename.

public enum ApplyPromptFormat: String, CaseIterable, Codable {
	case diff      = "Diff"
	case whole     = "Whole"
	/// Pro-only architect flow (delegate-edit capable)
	case architect = "Architect"
}

/// System prompt flavors for different preset types
public enum SystemPromptFlavor: String, Codable {
    case architectPlan       // planning/architecture (non-edit)
    case codeEditDiff        // code edits via diff (with allowRewrite flag handled upstream)
    case codeEditWhole       // whole-file rewrite
    case review              // legacy (unused) – use stored prompts instead
	case mcpAgent            // MCP Agent: autonomous agent using RepoPrompt MCP tools
	case mcpPairProgram      // MCP Pair Program: collaborative guidance via MCP tools
    case mcpPairPlan         // legacy (unused)
    case mcpDiscover         // Discover: context-first exploration
    case mcpBuilder          // MCP Builder: context_builder-driven implementation workflow
}
