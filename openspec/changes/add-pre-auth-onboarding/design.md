## Context

Today `AuthGate` (`Craw/AppShell/AuthGate.swift`) is a three-branch router driven by `Clerk.isLoaded` and `Clerk.user`:
1. `!isLoaded` → `SplashView`
2. `user == nil` → `AuthView(mode: .signInOrUp, isDismissable: false)`
3. `user != nil` → `RootView`

There is no SwiftData model, no `UserDefaults` key, and no Clerk metadata that represents "has finished onboarding." The product team has explicitly chosen to **not** persist onboarding answers in this first cut — they want to ship the UX cheaply, see whether the flow actually changes conversion or engagement, and only then commit to a persistence schema (whether SwiftData, Clerk public/unsafe metadata, or a backend `PATCH /v1/users/me` call).

The existing draft (`.claude/ONBOARDING_DRAFT_DETAILS.md`) is a React Native implementation from a prior project. It uses Lottie, `BouncyCheckbox`, expo-notifications, custom `WeekdaysPicker` / `TimerPicker` / `CountdownPicker` components, and inline RN styles. None of those map directly to this codebase; we keep the **shape** of the flow (six steps in the same order, same copy where applicable) and re-implement everything with SwiftUI primitives and Craw design tokens from `DESIGN.md`.

## Goals / Non-Goals

**Goals:**
- Render a six-step onboarding flow before `AuthView` on every cold launch when no Clerk session is active.
- Capture all answers in a single in-memory observable (`OnboardingState`) hosted at `AuthGate` scope.
- Match Craw's Airbnb-inspired design language (Rausch accent, pill primary button, generous rounding) — not the right-aligned 45pt RN draft.
- Cleanly hand off to the existing `AuthView` flow with zero changes to Clerk wiring.
- Provide a `-CrawSkipOnboarding YES` debug launch arg so engineers iterating on auth/post-auth don't replay the flow on every build.

**Non-Goals:**
- Persistence of onboarding answers (SwiftData, UserDefaults, Clerk metadata, backend write — all out).
- Resuming a half-completed flow across cold launches.
- Sending the captured schedule to `UNUserNotificationCenter` or asking for notification permission. The schedule step **only captures** weekdays + time into state.
- Lottie or any third-party animation runtime. v1 uses SF Symbols or static placeholder illustrations sized via the design tokens.
- Skip/back navigation across the whole flow (each step has Continue forward; an explicit Back is allowed within the flow but we will not let users exit to AuthView without completing the last step).
- Localization. Copy is English-only in v1, lifted verbatim from the RN draft where it makes sense.
- Analytics events for each step (a follow-up may add them).

## Decisions

### Decision 1 — Where the onboarding state lives

**Choice:** A new `@Observable @MainActor final class OnboardingState` instantiated as `@State` inside `AuthGate.body`, mirroring how `AuthSessionStore` is created today (`Craw/AppShell/AuthGate.swift:9`). The state is passed into `OnboardingView` via `.environment(state)` so deeply nested step views read/write it without prop drilling.

**Rationale:** `AuthGate` is the natural owner because (a) onboarding only matters while `user == nil`, which is exactly the branch `AuthGate` already discriminates, and (b) hoisting to `CrawApp` would mean the state survives sign-out, which is undesirable per the proposal ("after sign-out, return to auth screen, not onboarding").

**Alternatives considered:**
- A SwiftUI `@StateObject` at `CrawApp` scope — rejected: state outlives the auth-gate decision and complicates the rule "fresh start on every cold launch."
- A singleton (`OnboardingState.shared`) — rejected: harder to reset, encourages reaching past `AuthGate`, breaks the "session-scoped" contract.
- `UserDefaults` / SwiftData — rejected per Non-Goals; would require a migration story we don't want to ship yet.

### Decision 2 — Routing inside the `user == nil` branch

**Choice:** Replace the current `AuthView(...)` line in `AuthGate.contentForState` with a small inline switch:

```swift
} else if clerk.user == nil {
    if onboardingState.isCompleted || debugSkipOnboarding {
        AuthView(mode: .signInOrUp, isDismissable: false)
    } else {
        OnboardingView()
            .environment(onboardingState)
    }
}
```

`onboardingState.isCompleted` flips to `true` when the final step's "Continue" is tapped; SwiftUI re-evaluates `body` and swaps in `AuthView`. No `NavigationStack`, no transitions — the swap is the same root-view replacement that already happens between Splash → AuthView today.

**Rationale:** Keeps the gate's branching declarative and trivially diffable; no extra navigation infrastructure; works with Clerk's full-screen `AuthView`, which itself does not expect to be embedded inside a `NavigationStack`.

**Alternatives considered:**
- A `NavigationStack` with a `path: [OnboardingStep]` driving step-by-step pushes — rejected as overkill for a linear 6-step flow with no deep-link or restoration requirement, and it interferes with the "swap in AuthView at the end" pattern.
- A `TabView` with `.page` style — rejected because step transitions should be deterministic (driven by Continue), not swipe-based; horizontal swipes also fight with the time-picker step.

### Decision 3 — Step navigation inside `OnboardingView`

**Choice:** `OnboardingView` owns a `private @State var stepIndex: Int` and renders the current step via `@ViewBuilder switch stepIndex`. Each step view receives `onContinue: () -> Void` as a closure that increments `stepIndex` (or, on the last step, sets `state.isCompleted = true`). A top dot-progress (`OnboardingDotProgress(count: 6, active: stepIndex)`) is always visible.

**Rationale:** Six fixed steps, no branching, no skipping — a single integer is the simplest model. Step views remain pure SwiftUI subviews that take their slice of the state plus a "next" closure; they do not know about the index or each other.

**Alternatives considered:**
- An `enum OnboardingStep: CaseIterable` driving the switch — slightly nicer, accepted as a refinement during implementation if it doesn't add ceremony. Mentioned in tasks.md as a "may use" not a "must use."

### Decision 4 — Reusing existing design-system primitives

**Choice:** Add new files under `Craw/Onboarding/` for onboarding-specific composition, but **prefer reusing** existing `Theme` colors / fonts / radii from `Craw/DesignSystem/Theme.swift` and `Color+Hex.swift`. Only introduce a new component file (`OnboardingPrimaryButton.swift`, `OnboardingDotProgress.swift`, `OnboardingSelectableCard.swift`) when an existing primitive doesn't cover the use case.

**Rationale:** Avoids design drift; respects CLAUDE.md's rule against inventing tokens; keeps onboarding visually consistent with the dashboard the user lands in after signing in.

### Decision 5 — Step-specific input controls

| Step | Control | Rationale |
| --- | --- | --- |
| 1 Welcome | Static text + SF Symbol illustration + primary button | Pure intro, no input |
| 2 Pick Goal | `ForEach` of tappable rows with `Image(systemName: "circle"/"checkmark.circle.fill")` toggles. Multi-select. | SwiftUI-native, no third-party checkbox dep |
| 3 Daily Reading Time | Wheel-style `Picker` for minutes (5-min increments, 5–120 range) embedded in a sheet, with a large `h:mm` summary tap-target on the screen | Familiar iOS pattern, no custom countdown picker needed |
| 4 How To Read | Static bulleted text + primary button | No input |
| 5 Schedule | Custom weekday chip row (7 toggle buttons) + `DatePicker(selection:, displayedComponents: .hourAndMinute)` in `.compact` style | Native, accessible, dark-mode aware |
| 6 Books Per Year | Vertical stack of 4 single-select cards (`OnboardingSelectableCard`) with accent border on the selected one | Matches the draft's behavior; replaces the RN inline-styled `TouchableOpacity`s |

**Rationale:** Each control is either a SwiftUI built-in or a tiny local component. No new dependencies, no custom pickers ported from the RN codebase.

### Decision 6 — The "How To Read" copy

The RN draft has duplicated content (lines 89–94 repeat the title and bullets). We use the **bullet list only** in v1:

- Remove distractions before you start — especially social media.
- Don't just finish pages — understand them.
- Note if an idea or quote feels important.
- Summarize in your own words so you remember what you read.
- Pace yourself: take a short break every 20–30 minutes.

Copy is lightly cleaned up for typos (espesialy → especially) but kept faithful to the source.

### Decision 7 — The "Welcome" step copy + personal quote framing

The RN draft renders a long subtitle in addition to the "Welcome 👋" title. We keep the title plus the long subtitle verbatim (with the existing line breaks), but render the body **as a personal quote from the app's creator** rather than a generic marketing subtitle — this is the source of the human "I built this because I struggled with reading too" voice in the draft, and presenting it as a quote (with attribution + avatar) makes that voice explicit rather than implicit.

The attribution uses the existing `mike.imageset` already present in `Craw/Assets.xcassets`, loaded via `Image("mike")` and rendered as a small circular avatar next to a one-line name + role (e.g., `Mike, creator of Craw`). Quotation framing is one of: a large opening `"` glyph in the Rausch accent, an italic body, or a left-border quote block — picked during implementation to fit `DESIGN.md`. No SF Symbol or placeholder fallback for the avatar; the asset is already in the catalog and is required for this step.

The 20pt centered RN sizing is replaced by Craw `body-md` / `body-lg` tokens; final type choice happens during implementation against `DESIGN.md`.

### Decision 8 — Debug bypass

A new launch argument `-CrawSkipOnboarding YES` is honored by `OnboardingState.shouldSkipFromLaunchArgs`. When true, `AuthGate` treats `isCompleted` as if it were `true` immediately. Wrapped in `#if DEBUG` so release builds cannot be bypassed.

**Rationale:** Mirrors the existing `-CrawSeedSampleData YES` and `-CrawMockSearch YES` conventions documented in CLAUDE.md.

## Risks / Trade-offs

- **[Risk]** Users who quit the app mid-onboarding return to step 1 with no resumption. → **Mitigation:** Accepted explicitly as a Non-Goal. Flow is short (6 steps); persistence is a follow-up after we see drop-off data.
- **[Risk]** Onboarding answers are discarded — we won't be able to personalize the dashboard on first launch. → **Mitigation:** Accepted. A future change can add `PATCH /v1/users/me` on auth-bootstrap success to send the captured `OnboardingState`.
- **[Risk]** A user who signs out from Profile would expect to see the auth screen, not be replayed through onboarding. → **Mitigation:** `OnboardingState.isCompleted` is `@State` inside `AuthGate`. After first sign-in, the state instance survives sign-out (still inside the same `AuthGate` instance) so `isCompleted` remains `true` and the user goes straight to `AuthView`. Only a full app restart resets it. Verified manually as part of tasks.md.
- **[Risk]** The step-3 sheet-based time picker may feel heavier than the RN draft's inline picker. → **Mitigation:** If it tests poorly, we can swap to an inline `DatePicker(..., displayedComponents: .hourAndMinute)` using `.wheel` style without spec changes.
- **[Risk]** Without analytics, we can't measure step-by-step drop-off. → **Mitigation:** Out of scope for v1; tracked as Open Question.

## Migration Plan

This is additive UI in front of the existing auth screen. No data migration, no API changes, no `Info.plist` keys. Deploy path:

1. Ship the onboarding flow behind no remote flag — every cold launch with `user == nil` will see it. If we later want a kill switch, we can hard-code `OnboardingState.isCompleted = true` in one place.
2. Rollback is reverting the diff to `AuthGate.swift` plus deleting `Craw/Onboarding/`. No persisted state to clean up because nothing is written to disk.

## Open Questions

- **Analytics:** Do we want per-step `view` and `continue` events before launch, or fast-follow? Recommend fast-follow once an analytics provider is wired into the app.
- **Illustrations:** SF Symbols are acceptable placeholders. Do we want commissioned static illustrations (PNG/SVG) before launch, or post-launch? Recommend post-launch unless design has assets ready.
- **Yearly-goal "You tell me" option:** The RN draft makes this a first-class option but does not capture a number. v1 treats it as a sentinel value (`.unspecified`) in `OnboardingState` and surfaces no further prompt. Confirm with product before implementation.
- **Future persistence destination:** Once we decide to persist, will it be Clerk `publicMetadata`, SwiftData, or a backend `PATCH /v1/users/me`? The current `User` resource in `api-contract.yaml` doesn't model these fields. Out of scope for this change but worth flagging now so the next proposal can pick this up cleanly.
