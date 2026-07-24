import Foundation

/// How the file tree section is included in an assembled prompt.
/// Hoisted verbatim out of PromptViewModel.swift (it was a top-level enum
/// there) — decomposition step 6. Raw values persist; never rename.
public enum FileTreeOption: String, CaseIterable, Identifiable, Codable {
	case auto = "Auto"
	case files = "Full"
	case selected = "Selected"
	case none = "None"

	public var id: String { rawValue }
}
