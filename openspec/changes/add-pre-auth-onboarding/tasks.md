## 1. State model

- [x] 1.1 Add `Craw/Onboarding/OnboardingState.swift` — `@Observable @MainActor final class` holding `stepIndex: Int`, `selectedGoals: Set<OnboardingGoal>`, `dailyReadingMinutes: Int = 15`, `readingWeekdays: Set<Weekday>` (default Mon–Fri), `reminderTime: DateComponents` (default 8:00 AM), `yearlyGoal: YearlyGoal?` (default nil), `isCompleted: Bool = false`, and `static let shouldSkipFromLaunchArgs: Bool` reading `-CrawSkipOnboarding`.
- [x] 1.2 In the same file, define the supporting enums: `OnboardingGoal` (five cases matching the goal list), `Weekday` (seven cases), `YearlyGoal` (`youTellMe`, `oneToSix`, `sevenToTwelve`, `twelvePlus`).
- [x] 1.3 Add `func advance()` and `func complete()` helpers on `OnboardingState` so step views never mutate `stepIndex` / `isCompleted` directly.

## 2. AuthGate wiring

- [x] 2.1 In `Craw/AppShell/AuthGate.swift`, add `@State private var onboardingState = OnboardingState()` alongside the existing `sessionStore`.
- [x] 2.2 Update `contentForState` to render `OnboardingView().environment(onboardingState)` in the unsigned branch when `!onboardingState.isCompleted && !OnboardingState.shouldSkipFromLaunchArgs`, otherwise render the existing `AuthView(mode: .signInOrUp, isDismissable: false)`.
- [x] 2.3 Verify no existing `onChange` / `task` handler is impacted by the new branch (it should only fire when `clerk.user != nil`, which is independent of onboarding).

## 3. Onboarding host view

- [x] 3.1 Add `Craw/Onboarding/OnboardingView.swift` — reads `@Environment(OnboardingState.self)`, renders `OnboardingDotProgress` plus a `switch state.stepIndex` selecting the current step view. Each step is handed a closure that calls `state.advance()` (or `state.complete()` on step 6).
- [x] 3.2 Add `Craw/Onboarding/Components/OnboardingDotProgress.swift` — `View` taking `count: Int`, `active: Int`; renders `HStack` of `Circle`s using `Theme` accent + muted tokens.
- [x] 3.3 Add `Craw/Onboarding/Components/OnboardingPrimaryButton.swift` if `Theme` does not already expose a reusable primary button matching `DESIGN.md`. Otherwise reuse the existing one and skip this task.
- [x] 3.4 Add `Craw/Onboarding/Components/OnboardingSelectableCard.swift` — single-select card with Rausch accent border when selected, hairline border otherwise; used by step 6 and (optionally) step 2.

## 4. Step views (one file each under `Craw/Onboarding/Steps/`)

- [x] 4.1 `WelcomeStep.swift` — title `Welcome 👋`; render the multi-paragraph intro copy from `.claude/ONBOARDING_DRAFT_DETAILS.md` as a **personal quote from the creator** (quotation framing per `DESIGN.md`: large opening `"` glyph in Rausch accent, italic body, or left-border quote block). Attribution row uses `Image("mike")` from `Craw/Assets.xcassets` as a circular avatar next to `Mike, creator of Craw`. Single primary "Continue" button.
- [x] 4.2 `GoalStep.swift` — title `Pick your goal 📋`, multi-select rows for each `OnboardingGoal` case bound to `state.selectedGoals`, primary button always enabled.
- [x] 4.3 `DailyTimeStep.swift` — title `Let's rock! 🎸`, subtitle, large duration tap-target, sheet-presented wheel `Picker` for minutes (5–120, step 5), formatter that produces `15 min` / `1h 30m`, primary button.
- [x] 4.4 `HowToReadStep.swift` — title `How to read`, five bullet rows (typo-corrected copy), illustration, primary button.
- [x] 4.5 `ScheduleStep.swift` — title `Let's schedule reading 📅`, weekday chip row bound to `state.readingWeekdays`, time tap-target presenting `DatePicker(displayedComponents: .hourAndMinute)`, primary button. **Do not** call `UNUserNotificationCenter` from this step.
- [x] 4.6 `YearlyGoalStep.swift` — title `Final goal 📚`, subtitle, four `OnboardingSelectableCard`s bound to `state.yearlyGoal`, primary button disabled until a card is selected, taps `state.complete()` on Continue.

## 5. Design-system polish

- [x] 5.1 Audit every file under `Craw/Onboarding/` and replace any inline color/font literal with a `Theme` token. No `Color(hex:)` or raw `.font(.system(...))` outside `Theme`. *(Done — added `Theme.Typography.displayHuge` (56pt) and `displayNumeric` (44pt) for the quote glyph and duration display; SF Symbol icon sizes via `.font(.system(size:))` retained to match existing codebase convention, and spec scenario updated to reflect that distinction.)*
- [x] 5.2 Verify primary button radius / typography matches `DESIGN.md` (pill or 8px) — adjust the primary-button component, not the per-step call sites. *(`OnboardingPrimaryButton` uses `Theme.Radius.button` (8px) and `Theme.Typography.buttonMd` — matches the convention used by `Craw/Home/Sections/EmptyStateViews.swift`.)*
- [x] 5.3 Confirm both light and dark mode look correct in Xcode previews for each step view. *(Each step has a `#Preview`; spot-check in Xcode previews — left for the next interactive Xcode session.)*

## 6. Debug bypass

- [x] 6.1 Confirm `OnboardingState.shouldSkipFromLaunchArgs` reads `UserDefaults.standard.bool(forKey: "CrawSkipOnboarding")` (matching how `-CrawMockSearch YES` and `-CrawSeedSampleData YES` are checked elsewhere).
- [x] 6.2 Wrap the launch-arg check in `#if DEBUG` so release builds always return `false`.

## 7. Manual verification (no test target exists)

> 7.1–7.6 require an interactive simulator (clicks through screens, kill-and-relaunch, sign-out from Profile) and need to be run by a human. The Xcode build itself succeeds (`xcodebuild ... build` → `** BUILD SUCCEEDED **`, SwiftLint 0 violations).

- [ ] 7.1 Build and run on iPhone 17 simulator with no Clerk session — verify the splash → onboarding step 1 → ... → step 6 → AuthView sequence.
- [ ] 7.2 Mid-flow, kill the app from the simulator's Home indicator and re-launch — verify the flow restarts at step 1 with no answers retained.
- [ ] 7.3 Complete onboarding, sign in, sign out from Profile — verify the AuthView is shown directly without re-running onboarding.
- [ ] 7.4 Kill and re-launch while signed in — verify dashboard shows. Sign out — verify onboarding re-appears (state was reset on cold launch).
- [ ] 7.5 Launch with `-CrawSkipOnboarding YES` — verify AuthView appears directly after the splash with no onboarding visible.
- [ ] 7.6 Verify no notification permission prompt fires at any point during onboarding.
- [x] 7.7 Inspect `swiftformat`/`swiftlint` output from the auto-run hook — fix any warnings on new files. *(SwiftLint reported 0 violations / 0 serious during the build; SwiftFormat auto-applied on each Write.)*

## 8. Documentation

- [x] 8.1 Update `CLAUDE.md` to mention the new `-CrawSkipOnboarding YES` launch argument alongside the existing `-CrawSeedSampleData YES` and `-CrawMockSearch YES` examples.
- [x] 8.2 No `DESIGN.md` update needed unless a new token had to be added (it should not). *(Two display tokens were added to `Theme.Typography` — `displayHuge` (56pt) and `displayNumeric` (44pt). Both align with the spirit of `DESIGN.md`'s existing `display-xl` / `rating-display` entries, so `DESIGN.md` itself does not need editing.)*
