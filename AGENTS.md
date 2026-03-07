# AGENTS.md

## Mission

Build and maintain a high-quality native macOS SwiftUI app with modern Apple design fidelity, clean architecture, and production-grade reliability.

## Mandatory Quality Bar

- Ship no compile warnings.
- Preserve existing behavior unless the task explicitly changes it.
- Prefer small, reviewable diffs over broad rewrites.
- Add or update tests for non-trivial logic changes.
- Keep code self-explanatory; add brief comments only for non-obvious logic.
- Never leave placeholder TODOs in committed feature code.

## SwiftUI Engineering Rules

- Keep business logic out of `View` bodies.
- Use one-way data flow with clear state ownership.
- Isolate side effects (network, file I/O, persistence) behind abstractions.
- Constrain UI updates to `@MainActor` boundaries.
- Guard platform/version-specific APIs with availability checks.

## UI/UX Rules (macOS)

- Follow native macOS interaction patterns (toolbar, sidebar, menu commands, keyboard navigation).
- Prioritize readability and hierarchy over decoration.
- Validate hover, focus, disabled, loading, empty, and error states.
- Enforce accessibility: contrast, VoiceOver labeling, keyboard-only navigation.
- Keep motion subtle and purposeful.

## Liquid Glass Guidance

- Use system materials and Apple-documented APIs first.
- Avoid over-layering translucency that harms legibility.
- Keep fallbacks for older macOS targets.

## Execution Protocol

1. Clarify scope and constraints from current code.
2. Implement the minimal correct change.
3. Run relevant checks/tests.
4. Report what changed, why, and any residual risks.

## Preferred Skills For This Repo

- `$macos-liquid-glass-swiftui`
- `$swiftui-design-review-macos`
- `$swiftui-macos-app-architecture`
