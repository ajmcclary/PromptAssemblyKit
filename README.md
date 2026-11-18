# PromptAssemblyKit

Deterministic prompt assembly for code-context tools: which sections a prompt contains, in what
order, and under which preset.

A tool that copies code context to an LLM (file tree, file contents, git diff, meta prompts,
user instructions) has to decide what to include and how to join it. PromptAssemblyKit holds
those decisions as plain values and pure functions: a section vocabulary and order-driven
builder, copy presets with stable built-ins, a resolver that merges a preset with per-workspace
customizations and UI defaults, and a codec for a saved-prompt library. The same inputs always
produce the same prompt. Rendering each section's text and storing anything on disk are up to
the caller.

## What's inside

- **Assembly** — `PromptSection` (file map, file contents, git diff, diff formatting, meta
  prompts, user instructions) and `PromptAssemblyBuilder`, which joins caller-rendered snippets
  in a given order with optional disabled sections and an optional duplicate of the user
  instructions at the top. `PromptAssemblyBuilder.defaultSectionOrder` is the standard order.
- **Copy presets** — `CopyPreset` (each field optional: `nil` means "use the current UI
  state"), `CopyPresetKind`, and `BuiltInCopyPresets` (`standard`, `plan`, `manual`,
  `codeReview`, `mcpAgent`, ... with stable UUIDs; lookup by kind or ID).
- **Customization** — `CopyCustomizations` (per-workspace overrides, applied only to the Manual
  preset) and `CopyPresetOverrides` (user edits to a built-in, `trimmed(against:)` to keep only
  real differences).
- **Resolution** — `PromptContextResolver.resolve(preset:custom:ui:)` merges preset,
  customizations and `PromptContextResolver.UIDefaults` into a `PromptContextResolved`, with
  helpers for the global code-map switch and per-call code-map overrides.
- **Vocabulary** — `FileTreeOption`, `CodeMapUsage`, `GitInclusion` (with
  `fromMCPScope(_:)`), `ApplyPromptFormat`, `SystemPromptFlavor`. Raw values are persisted and
  stable.
- **Prompt library** — `StoredPrompt`, the `PromptExport` import/export DTO, and
  `PromptLibraryCodec` (JSON encode/decode plus `mergeExternalPrompts`, which skips
  title-and-content duplicates).

## When to use it

- You build prompts from several independently rendered context blocks and want a fixed,
  testable ordering and inclusion policy.
- You offer named copy presets and need one place that decides what a preset plus local
  overrides actually means.
- You import, export or merge a library of saved prompts as JSON.

## When not to use it

- **Agent sessions, transcripts, turn composition for agent runs:** use AgentRuntimeKit (and
  AgentExecutionKit to run agents).
- **Applying model-proposed edits back to files:** use ApplyEditsKit.
- **Sending prompts to a model:** this package never calls a provider.
- Out of scope here: UI and view models, UserDefaults and other persistence backends,
  filesystem I/O, workspace selection and indexing, file-tree and code-map rendering, provider
  launch/transport/authentication, MCP server implementation, and stateful prompt coordinators.

## Installation

```swift
dependencies: [
    // 0.1.0-beta.3 is a prerelease identifier — SwiftPM only resolves
    // prerelease tags when the lower bound itself names one.
    .package(url: "https://github.com/ajmcclary/PromptAssemblyKit.git", .upToNextMinor(from: "0.1.0-beta.3"))
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [.product(name: "PromptAssemblyKit", package: "PromptAssemblyKit")]
)
```

## Usage

```swift
import Foundation
import PromptAssemblyKit

// 1. Resolve what a copy should contain: preset + workspace overrides + UI fallbacks.
let ui = PromptContextResolver.UIDefaults(
    xmlCopyPromptFormat: .diff, fileTreeOption: .selected, codeMapUsage: .auto,
    gitInclusion: .none, codeMapsGloballyDisabled: false
)
let resolved = PromptContextResolver.resolve(
    preset: BuiltInCopyPresets.manual,
    custom: CopyCustomizations(gitInclusion: .selected),  // honoured for the Manual preset only
    ui: ui
)

// 2. Assemble caller-rendered sections in a deterministic order.
var snippets: [PromptSection: String] = [
    .userInstructions: "<user_instructions>Fix the crash</user_instructions>",
    .fileContents: "<file_contents>…</file_contents>"
]
if resolved.rendersFileTree { snippets[.fileMap] = "<file_map>…</file_map>" }

let prompt = PromptAssemblyBuilder.build(
    order: PromptAssemblyBuilder.defaultSectionOrder, disabled: [],
    duplicateUserInstructionsAtTop: true, snippets: snippets
)

// 3. Import a shared prompt library, skipping (title, content) duplicates.
let shared = try PromptLibraryCodec.encodeExports([
    StoredPrompt(id: UUID(), title: "Reviewer", content: "Review for regressions.")
])
let (library, added) = PromptLibraryCodec.mergeExternalPrompts(
    current: [], external: try PromptLibraryCodec.decodeExports(shared)
)
```

## Requirements

- Swift tools 6.0, Swift 6 language mode with strict concurrency.
- macOS 27.0 / iOS 27.0.
- Dependencies: none (Foundation only).

## Stability

Pre-1.0 (`0.1.0-beta.x`): the public API may change between minor versions, so pin with
`.upToNextMinor`.

## Development

```sh
swift build
swift test   # fast; pure value types and deterministic policies
```

## Origin

Extracted from the RepoPrompt app.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
