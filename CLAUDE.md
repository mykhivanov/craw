# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Craw** — a SwiftUI iOS/iPadOS app (universal: `TARGETED_DEVICE_FAMILY = "1,2"`). Bundle ID `com.mykhivanov.Craw`. Built with Xcode 26.5, deployment target iOS 26.5, Swift 5.10. The current source is scaffolding only (`Craw/CrawApp.swift` + a stub `Craw/ContentView.swift` rendering "Hello, world!").

## Build & run

This is an Xcode-managed project (`Craw.xcodeproj`) — there is no SwiftPM `Package.swift`. There are no tests yet (no test target in the project).

```bash
# Inspect targets / schemes
xcodebuild -project Craw.xcodeproj -list

# Build for simulator
xcodebuild -project Craw.xcodeproj -scheme Craw -destination 'platform=iOS Simulator,name=iPhone 17' build

# Or just: open Craw.xcodeproj && ⌘R
```

## Sample data (debug builds)

In DEBUG configurations, the app can self-seed two in-progress books, one finished book, and seven days of reading activity producing a visible 4-day streak and positive day-over-day pages delta. Enable by passing the launch argument:

```
-CrawSeedSampleData YES
```

This sets `UserDefaults.standard.bool(forKey: "CrawSeedSampleData")` to `true`. `SampleData.seedIfEmpty(into:)` is idempotent — it skips seeding if any `Book` or `ReadingDay` rows already exist. Seeding code is wrapped in `#if DEBUG` and excluded from release builds.

To exercise the empty-state UI, launch without the argument (or delete the simulator app first to clear persisted data).

## Adding files — do NOT edit `project.pbxproj`

The project uses Xcode 16's `PBXFileSystemSynchronizedRootGroup` for the `Craw/` folder (see `fileSystemSynchronizedGroups` in `project.pbxproj`). **Any Swift file you create inside `Craw/` is automatically part of the target** — no pbxproj edits needed, no Xcode "Add Files" dance. Just write the file. Conversely, deleting a file from disk removes it from the target.

## Lint & format — runs automatically

`.claude/settings.json` defines a `PostToolUse` hook on `Write|Edit` that runs `swiftformat` then `swiftlint` against any `.swift` file you touch. You don't need to invoke these manually. Configs:

- `.swiftformat` — 4-space indent, 120-col width, `--self remove`, LF line endings, Swift 5.10.
- `.swiftlint.yml` — light ruleset tuned for SwiftUI (disables `identifier_name`, `type_name`, `line_length`, `multiple_closures_with_trailing_closure`, etc.). Soft limits only — warnings, never errors.

SwiftLint also runs as an Xcode build phase (`BB1A57500000000000000001` in `project.pbxproj`); it expects `swiftlint` on PATH (homebrew). If missing it warns rather than failing the build.

Install tooling if it's not present: `brew install swiftformat swiftlint`.

## Design system — `DESIGN.md`

`DESIGN.md` is the canonical design spec for the UI: an Airbnb-style aesthetic — white canvas, single Rausch accent (`#ff385c`), modest type weights (Airbnb Cereal VF / Inter fallback), generous rounding (8px buttons, 14px cards, fully-pill search), one shadow tier. **Any UI work should reference its color, typography, spacing, rounding, and component tokens** rather than inventing new ones. Sub-brand colors (Luxe `#460479`, Plus `#92174d`) are scoped to sub-products only.

## OpenSpec workflow

The repo is set up for [OpenSpec](https://github.com/Fission-AI/OpenSpec) spec-driven development. `openspec/` holds `config.yaml`, `changes/` (with `archive/`), and `specs/` (currently empty). Slash commands are installed under `.claude/commands/opsx/`:

- `/opsx:propose` — create a change proposal with design + specs + tasks in one step
- `/opsx:explore` — think through a problem before proposing
- `/opsx:apply` — implement tasks from a proposed change
- `/opsx:archive` — finalize a completed change

Use these for non-trivial work; ad-hoc edits to a scratch SwiftUI view don't need the workflow.
