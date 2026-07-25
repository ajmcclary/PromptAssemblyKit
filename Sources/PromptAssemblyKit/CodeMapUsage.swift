import Foundation

/// Determines how CodeMap definitions are inserted.
/// Hoisted verbatim out of CodeMapExtractor.swift (it was a top-level enum
/// there) — decomposition step 6. Raw values persist; never rename.
public enum CodeMapUsage: String, CaseIterable, Codable, Sendable {
	case auto
	case complete
	/// Include code-map for selected files only (handled at injection sites;
	/// returning it here would duplicate).
	case selected
	case none
}
