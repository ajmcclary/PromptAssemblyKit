import Foundation

/// Workspace-specific customization overrides for a copy preset
/// These allow per-workspace deviations from the base preset configuration
public struct CopyCustomizations: Equatable, Sendable {
    // Meta prompts selection
    public var selectedPromptIDs: [UUID]?
    
    // Content configuration overrides
    public var fileTreeMode: FileTreeOption?
    public var codeMapUsage: CodeMapUsage?
    public var gitInclusion: GitInclusion?
    
    // Include flags overrides
    public var includeFiles: Bool?
    public var includeUserPrompt: Bool?
    public var includeMetaPrompts: Bool?
    public var includeFileTree: Bool?
    
    // XML format override
    public var xmlFormat: ApplyPromptFormat?
    
    // System prompt override
    public var systemPromptFlavor: SystemPromptFlavor?
    
    // MCP metadata override
    public var includeMCPMetadata: Bool?
    
    // MARK: - Initializer
    public init(
        selectedPromptIDs: [UUID]? = nil,
        fileTreeMode: FileTreeOption? = nil,
        codeMapUsage: CodeMapUsage? = nil,
        gitInclusion: GitInclusion? = nil,
        includeFiles: Bool? = nil,
        includeUserPrompt: Bool? = nil,
        includeMetaPrompts: Bool? = nil,
        includeFileTree: Bool? = nil,
        xmlFormat: ApplyPromptFormat? = nil,
        systemPromptFlavor: SystemPromptFlavor? = nil,
        includeMCPMetadata: Bool? = nil
    ) {
        self.selectedPromptIDs = selectedPromptIDs
        self.fileTreeMode = fileTreeMode
        self.codeMapUsage = codeMapUsage
        self.gitInclusion = gitInclusion
        self.includeFiles = includeFiles
        self.includeUserPrompt = includeUserPrompt
        self.includeMetaPrompts = includeMetaPrompts
        self.includeFileTree = includeFileTree
        self.xmlFormat = xmlFormat
        self.systemPromptFlavor = systemPromptFlavor
        self.includeMCPMetadata = includeMCPMetadata
    }
    
    /// Check if any customizations are present
    public var hasCustomizations: Bool {
        selectedPromptIDs != nil ||
        fileTreeMode != nil ||
        codeMapUsage != nil ||
        gitInclusion != nil ||
        includeFiles != nil ||
        includeUserPrompt != nil ||
        includeMetaPrompts != nil ||
        includeFileTree != nil ||
        xmlFormat != nil ||
        systemPromptFlavor != nil ||
        includeMCPMetadata != nil
    }
    
	/// Clear all customizations
	public mutating func clear() {
		selectedPromptIDs = nil
        fileTreeMode = nil
        codeMapUsage = nil
        gitInclusion = nil
        includeFiles = nil
        includeUserPrompt = nil
        includeMetaPrompts = nil
        includeFileTree = nil
        xmlFormat = nil
		systemPromptFlavor = nil
		includeMCPMetadata = nil
	}

	/// Returns a copy with only the codemap usage override cleared.
	/// Used to collapse legacy Manual-mode duplicate state while preserving
	/// all other customization fields.
	public func removingCodeMapUsageOverride() -> CopyCustomizations {
		var copy = self
		copy.codeMapUsage = nil
		return copy
	}
}

// MARK: - Codable Conformance

extension CopyCustomizations: Codable {
    public enum CodingKeys: String, CodingKey {
        case selectedPromptIDs
        case fileTreeMode
        case codeMapUsage
        case gitInclusion
        case includeFiles
        case includeUserPrompt
        case includeMetaPrompts
        case includeFileTree
        case xmlFormat
        case systemPromptFlavor
        case includeMCPMetadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedPromptIDs = try container.decodeIfPresent([UUID].self, forKey: .selectedPromptIDs)
        
        fileTreeMode = try container.decodeIfPresent(FileTreeOption.self, forKey: .fileTreeMode)
        codeMapUsage = try container.decodeIfPresent(CodeMapUsage.self, forKey: .codeMapUsage)
        gitInclusion = try container.decodeIfPresent(GitInclusion.self, forKey: .gitInclusion)
        includeFiles = try container.decodeIfPresent(Bool.self, forKey: .includeFiles)
        includeUserPrompt = try container.decodeIfPresent(Bool.self, forKey: .includeUserPrompt)
        includeMetaPrompts = try container.decodeIfPresent(Bool.self, forKey: .includeMetaPrompts)
        includeFileTree = try container.decodeIfPresent(Bool.self, forKey: .includeFileTree)
        xmlFormat = try container.decodeIfPresent(ApplyPromptFormat.self, forKey: .xmlFormat)
        systemPromptFlavor = try container.decodeIfPresent(SystemPromptFlavor.self, forKey: .systemPromptFlavor)
        includeMCPMetadata = try container.decodeIfPresent(Bool.self, forKey: .includeMCPMetadata)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(selectedPromptIDs, forKey: .selectedPromptIDs)
        try container.encodeIfPresent(fileTreeMode, forKey: .fileTreeMode)
        try container.encodeIfPresent(codeMapUsage, forKey: .codeMapUsage)
        try container.encodeIfPresent(gitInclusion, forKey: .gitInclusion)
        try container.encodeIfPresent(includeFiles, forKey: .includeFiles)
        try container.encodeIfPresent(includeUserPrompt, forKey: .includeUserPrompt)
        try container.encodeIfPresent(includeMetaPrompts, forKey: .includeMetaPrompts)
        try container.encodeIfPresent(includeFileTree, forKey: .includeFileTree)
        try container.encodeIfPresent(xmlFormat, forKey: .xmlFormat)
        try container.encodeIfPresent(systemPromptFlavor, forKey: .systemPromptFlavor)
        try container.encodeIfPresent(includeMCPMetadata, forKey: .includeMCPMetadata)
    }
}
