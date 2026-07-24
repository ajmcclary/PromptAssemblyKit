// swift-tools-version: 6.0
import PackageDescription

// PromptAssemblyKit — deterministic prompt-assembly vocabulary and policies.
//
// Promoted verbatim out of RepoPrompt's internal RepoPromptCore package
// (its PromptAssemblyCore target) as the second extraction of the
// migrate.md package map. RepoPromptCore's PromptAssemblyCore target is
// now an @_exported re-export shim over this package (the AgentRuntimeKit
// / WorkspacePaths → WorkspacePathsCore promotion precedent).
//
// Scope: prompt section identity, ordering, and deterministic assembly
// (PromptSection, PromptAssemblyBuilder); copy-preset value models and
// built-ins (CopyPreset, CopyPresetKind, BuiltInCopyPresets) with their
// per-workspace customization and override values (CopyCustomizations,
// CopyPresetOverrides); the prompt-context resolution matrix
// (PromptContextResolver, PromptContextResolved); the generic prompt
// vocabulary enums (FileTreeOption, CodeMapUsage, GitInclusion,
// ApplyPromptFormat, SystemPromptFlavor); and the prompt-library codec +
// merge policy (StoredPrompt, PromptExport, PromptLibraryCodec).
// Deliberately OUT of scope: SwiftUI/AppKit and view models,
// UserDefaults/persistence backends and filesystem I/O, workspace
// selection and indexing, provider launch/transport/authentication, MCP
// server implementation, and the app's stateful prompt coordinators
// (PromptViewModel, PromptStorage, SystemPromptService stay app-side).
//
// Zero package dependencies (Foundation only). Swift 5 language mode
// keeps the moved code byte-behaviorally identical (AgentRuntimeKit /
// RepoPromptCore promoted-target precedent).
let package = Package(
    name: "PromptAssemblyKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PromptAssemblyKit", targets: ["PromptAssemblyKit"])
    ],
    targets: [
        .target(
            name: "PromptAssemblyKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "PromptAssemblyKitTests",
            dependencies: ["PromptAssemblyKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
