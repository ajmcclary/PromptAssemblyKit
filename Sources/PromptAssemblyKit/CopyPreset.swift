import Foundation

// MARK: - Enums

/// Built-in option labels (stable IDs for migration & referencing)
public enum CopyPresetKind: String, Codable, CaseIterable {
    case standard      // Standard default preset
    case plan          // Architect planning copy
    case manual        // Manual current behavior
    case editXML       // XML diff copy
    case proEdit       // Legacy raw value for delegated architect apply (parallel)
    case diffFollowUp  // Git-selected only; no files/prompts/tree
    case codeReview    // Review w/ git diff
    case mcpAgent      // MCP Claude Code + codemap compression
    case mcpPair       // MCP Pair Program
    case mcpPlan       // MCP Pair Plan
    case mcpBuilder    // MCP Builder: context_builder-driven implementation
}

/// How to include git diff in the copy
public enum GitInclusion: String, Codable, CaseIterable {
    case none
    case selected
    case complete
}

// MARK: - Copy Preset Model

/// Copy preset describes behavior at a high level.
/// Some fields are optional overrides; unspecified means "use current workspace/UI state".
public struct CopyPreset: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let builtInKind: CopyPresetKind?
    public let description: String?
    public let icon: String?               // e.g. "🏗️", "📝", "⚡", etc.
    public let isBuiltIn: Bool
    
    // Behavior flags - nil means use current UI state
    public var includeFiles: Bool?
    public var includeUserPrompt: Bool?
    public var includeMetaPrompts: Bool?
    public var includeFileTree: Bool?
    
    // Content shaping - nil means use current UI state
    public var xmlFormat: ApplyPromptFormat?       // nil for none; else .diff/.whole/.architect
    public var fileTreeMode: FileTreeOption?       // overrides PromptViewModel.fileTreeOption
    public var codeMapUsage: CodeMapUsage?         // overrides PromptViewModel.codeMapUsage
    public var gitInclusion: GitInclusion?         // git diff policy
    
    // Special prompt/system behaviors
    public var systemPromptFlavor: SystemPromptFlavor? // For specialized system prompts
    public var storedPromptIds: [UUID]?                // IDs of stored prompts to include
    public var notes: String?                          // Additional notes for user reference
    public var includeMCPMetadata: Bool?               // Include MCP metadata block (window/tab info)
    
    // MARK: - Initializer
    public init(
        id: UUID = UUID(),
        name: String,
        builtInKind: CopyPresetKind? = nil,
        description: String? = nil,
        icon: String? = nil,
        isBuiltIn: Bool = false,
        includeFiles: Bool? = nil,
        includeUserPrompt: Bool? = nil,
        includeMetaPrompts: Bool? = nil,
        includeFileTree: Bool? = nil,
        xmlFormat: ApplyPromptFormat? = nil,
        fileTreeMode: FileTreeOption? = nil,
        codeMapUsage: CodeMapUsage? = nil,
        gitInclusion: GitInclusion? = nil,
        systemPromptFlavor: SystemPromptFlavor? = nil,
        storedPromptIds: [UUID]? = nil,
        notes: String? = nil,
        includeMCPMetadata: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.builtInKind = builtInKind
        self.description = description
        self.icon = icon
        self.isBuiltIn = isBuiltIn
        self.includeFiles = includeFiles
        self.includeUserPrompt = includeUserPrompt
        self.includeMetaPrompts = includeMetaPrompts
        self.includeFileTree = includeFileTree
        self.xmlFormat = xmlFormat
        self.fileTreeMode = fileTreeMode
        self.codeMapUsage = codeMapUsage
        self.gitInclusion = gitInclusion
        self.systemPromptFlavor = systemPromptFlavor
        self.storedPromptIds = storedPromptIds
        self.notes = notes
        self.includeMCPMetadata = includeMCPMetadata
    }
}

// MARK: - Codable Conformance

extension CopyPreset: Codable {
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case builtInKind
        case description
        case icon
        case isBuiltIn
        case includeFiles
        case includeUserPrompt
        case includeMetaPrompts
        case includeFileTree
        case xmlFormat
        case fileTreeMode
        case codeMapUsage
        case gitInclusion
        case systemPromptFlavor
        case storedPromptIds
        case notes
        case includeMCPMetadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        builtInKind = try container.decodeIfPresent(CopyPresetKind.self, forKey: .builtInKind)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        isBuiltIn = try container.decode(Bool.self, forKey: .isBuiltIn)
        includeFiles = try container.decodeIfPresent(Bool.self, forKey: .includeFiles)
        includeUserPrompt = try container.decodeIfPresent(Bool.self, forKey: .includeUserPrompt)
        includeMetaPrompts = try container.decodeIfPresent(Bool.self, forKey: .includeMetaPrompts)
        includeFileTree = try container.decodeIfPresent(Bool.self, forKey: .includeFileTree)
        
        xmlFormat = try container.decodeIfPresent(ApplyPromptFormat.self, forKey: .xmlFormat)
        fileTreeMode = try container.decodeIfPresent(FileTreeOption.self, forKey: .fileTreeMode)
        codeMapUsage = try container.decodeIfPresent(CodeMapUsage.self, forKey: .codeMapUsage)
        
        gitInclusion = try container.decodeIfPresent(GitInclusion.self, forKey: .gitInclusion)
        systemPromptFlavor = try container.decodeIfPresent(SystemPromptFlavor.self, forKey: .systemPromptFlavor)
        storedPromptIds = try container.decodeIfPresent([UUID].self, forKey: .storedPromptIds)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        includeMCPMetadata = try container.decodeIfPresent(Bool.self, forKey: .includeMCPMetadata)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(builtInKind, forKey: .builtInKind)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encode(isBuiltIn, forKey: .isBuiltIn)
        try container.encodeIfPresent(includeFiles, forKey: .includeFiles)
        try container.encodeIfPresent(includeUserPrompt, forKey: .includeUserPrompt)
        try container.encodeIfPresent(includeMetaPrompts, forKey: .includeMetaPrompts)
        try container.encodeIfPresent(includeFileTree, forKey: .includeFileTree)
        try container.encodeIfPresent(xmlFormat, forKey: .xmlFormat)
        try container.encodeIfPresent(fileTreeMode, forKey: .fileTreeMode)
        try container.encodeIfPresent(codeMapUsage, forKey: .codeMapUsage)
        try container.encodeIfPresent(gitInclusion, forKey: .gitInclusion)
        try container.encodeIfPresent(systemPromptFlavor, forKey: .systemPromptFlavor)
        try container.encodeIfPresent(storedPromptIds, forKey: .storedPromptIds)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(includeMCPMetadata, forKey: .includeMCPMetadata)
    }
}

// MARK: - Resolved Configuration

/// A resolved, runtime config after merging preset + workspace overrides + capability checks.
/// Used by both copy and chat prompt builders.
public struct PromptContextResolved {
    public var includeFiles: Bool
    public var includeUserPrompt: Bool
    public var includeMetaPrompts: Bool
    public var includeFileTree: Bool
    
    public var xmlFormat: ApplyPromptFormat?      // nil => no XML block
    public var fileTreeMode: FileTreeOption
    public var codeMapUsage: CodeMapUsage
    public var gitInclusion: GitInclusion
    
    public var systemPromptFlavor: SystemPromptFlavor?
    public var storedPromptIds: [UUID]?           // IDs of stored prompts to include
    public var includeMCPMetadata: Bool           // Include MCP metadata block (window/tab info)

    public init(
        includeFiles: Bool,
        includeUserPrompt: Bool,
        includeMetaPrompts: Bool,
        includeFileTree: Bool,
        xmlFormat: ApplyPromptFormat?,
        fileTreeMode: FileTreeOption,
        codeMapUsage: CodeMapUsage,
        gitInclusion: GitInclusion,
        systemPromptFlavor: SystemPromptFlavor?,
        storedPromptIds: [UUID]?,
        includeMCPMetadata: Bool
    ) {
        self.includeFiles = includeFiles
        self.includeUserPrompt = includeUserPrompt
        self.includeMetaPrompts = includeMetaPrompts
        self.includeFileTree = includeFileTree
        self.xmlFormat = xmlFormat
        self.fileTreeMode = fileTreeMode
        self.codeMapUsage = codeMapUsage
        self.gitInclusion = gitInclusion
        self.systemPromptFlavor = systemPromptFlavor
        self.storedPromptIds = storedPromptIds
        self.includeMCPMetadata = includeMCPMetadata
    }
}

public extension PromptContextResolved {
    /// Whether the resolved copy context should render an ASCII file tree.
    /// Code maps can still produce a <file_map> section independently.
    public var rendersFileTree: Bool {
        includeFileTree && fileTreeMode != .none
    }
    
    public var effectiveFileTreeMode: FileTreeOption {
        rendersFileTree ? fileTreeMode : .none
    }
}