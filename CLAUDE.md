# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Craw** — a SwiftUI iOS/iPadOS app (universal: `TARGETED_DEVICE_FAMILY = "1,2"`). Bundle ID `com.mykhivanov.Craw`. Built with Xcode 26.5, deployment target iOS 26.5, Swift 5.10.

The app gates the dashboard behind a Clerk-authenticated session (`AuthGate` → splash → `AuthView` → `RootView`). Book search hits a custom backend at `https://api.craw.app/v1` via `CrawAPIClient`, which attaches the current Clerk JWT to every request. Library, reading sessions, quotes, thoughts, and activity remain local-only in SwiftData (the backend's `User` resource is hydrated with the library structure for future sync — see `openspec/changes/add-auth-and-book-search/api-contract.yaml`).

## Required configuration

Three `Info.plist` keys must be present at launch. `CLERK_PUBLISHABLE_KEY` is surfaced via the Xcode build setting `INFOPLIST_KEY_CLERK_PUBLISHABLE_KEY`; `CRAW_API_BASE_URL` and `REVENUECAT_PUBLIC_KEY` are written directly into the committed `Craw/Info.plist` for local dev convenience:

| Key                       | Purpose                                                                            | Default if unset                                                          |
| ------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `CLERK_PUBLISHABLE_KEY`   | Clerk dashboard → API Keys → Publishable key. Assertion fires in DEBUG if missing. | none (asserts)                                                            |
| `CRAW_API_BASE_URL`       | Backend base URL. Override in staging.                                             | `https://api.craw.app/v1`                                                 |
| `REVENUECAT_PUBLIC_KEY`   | RevenueCat dashboard → Project settings → Apple App Store → Public app-specific key. Drives the paywall + monthly subscription. | DEBUG falls back to the embedded Apple App Store public key (`appl_kcwccoejaIlFNlWwefZHjJTtfbm`); RELEASE asserts. |

**Local setup:** in Xcode, select the Craw target → Build Settings → search "INFOPLIST_KEY" → add `INFOPLIST_KEY_CLERK_PUBLISHABLE_KEY = pk_test_...`. For CI, plumb the value through xcconfig substitution so the key is never committed to git.

**Clerk dashboard:** under "Native Applications" register the iOS app with bundle id `com.mykhivanov.Craw` and add the redirect URL `com.mykhivanov.Craw://clerk-callback`. The matching URL scheme `com.mykhivanov.Craw` must also be registered in `Info.plist`'s `CFBundleURLTypes` — `INFOPLIST_KEY_*` build settings don't cover structural array-of-dict entries, so add the URL scheme via Xcode → target → Info → URL Types (or create a real `Info.plist` file and point `INFOPLIST_FILE` at it).

**SwiftPM dependency:** Clerk is consumed via `https://github.com/clerk/clerk-ios` — add via Xcode → File → Add Package Dependencies. Add both `ClerkKit` and `ClerkKitUI` products to the Craw target.

**RevenueCat dependency:** RevenueCat is consumed via `https://github.com/RevenueCat/purchases-ios-spm.git` (already added as a package reference in `Craw.xcodeproj`). The `RevenueCat` product must be linked to the Craw target — Xcode → Craw target → General → Frameworks, Libraries, and Embedded Content → `+` → choose `RevenueCat`. A single auto-renewing monthly product `CRAW_MONTHLY_15` is configured in App Store Connect and mapped in the RevenueCat dashboard to entitlement `Craw Membership` under offering `default`.

**Mock search (DEBUG):** to exercise the search UI without the backend, launch with `-CrawMockSearch YES`. `MockBookSearchService` returns three fixture results filtered by query substring.

**Skip onboarding (DEBUG):** the app shows a 6-step in-memory onboarding flow before `AuthView` on every cold launch when no Clerk session is restored. To bypass it while iterating on auth or post-auth flows, launch with `-CrawSkipOnboarding YES`. `OnboardingState.shouldSkipFromLaunchArgs` is `#if DEBUG`-only so release builds always render the flow. Onboarding answers are intentionally not persisted — killing and re-launching the app restarts the flow at step 1.

## Build & run

This is an Xcode-managed project (`Craw.xcodeproj`) — there is no top-level `Package.swift`, but SwiftPM dependencies (e.g., `clerk-ios`) are pulled in via Xcode's "Add Package Dependencies". There are no tests yet (no test target in the project).

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
