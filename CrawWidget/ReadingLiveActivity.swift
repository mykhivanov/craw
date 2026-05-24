import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

private enum LiveActivityPalette {
    static let rausch = Color(red: 1.0, green: 0x38 / 255.0, blue: 0x5C / 255.0)
    static let ink = Color(red: 0x22 / 255.0, green: 0x22 / 255.0, blue: 0x22 / 255.0)
    static let muted = Color(red: 0x6A / 255.0, green: 0x6A / 255.0, blue: 0x6A / 255.0)
    static let surfaceSoft = Color(red: 0xF7 / 255.0, green: 0xF7 / 255.0, blue: 0xF7 / 255.0)
    static let canvas = Color.white
}

struct ReadingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(LiveActivityPalette.canvas)
                .activitySystemActionForegroundColor(LiveActivityPalette.ink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.bookTitle)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.attributes.bookAuthor)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerLabel(state: context.state)
                        .font(.system(.title3, design: .rounded).monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ControlsRow(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "book.fill")
                    .foregroundStyle(LiveActivityPalette.rausch)
            } compactTrailing: {
                TimerLabel(state: context.state)
                    .monospacedDigit()
                    .font(.caption2)
            } minimal: {
                Image(systemName: context.state.phase == .running ? "book.fill" : "pause.fill")
                    .foregroundStyle(LiveActivityPalette.rausch)
            }
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<ReadingActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.bookTitle)
                        .font(.headline)
                        .foregroundStyle(LiveActivityPalette.ink)
                        .lineLimit(1)
                    Text(context.attributes.bookAuthor)
                        .font(.caption)
                        .foregroundStyle(LiveActivityPalette.muted)
                        .lineLimit(1)
                }
                Spacer()
                Text("p. \(context.state.currentPage) / \(context.attributes.totalPages)")
                    .font(.caption)
                    .foregroundStyle(LiveActivityPalette.muted)
                    .monospacedDigit()
            }

            HStack {
                TimerLabel(state: context.state)
                    .font(.system(size: 36, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(LiveActivityPalette.ink)
                Spacer()
                Text(context.state.phase == .paused ? "Paused" : "Reading")
                    .font(.caption)
                    .foregroundStyle(LiveActivityPalette.muted)
            }

            ControlsRow(state: context.state)
        }
        .padding(16)
    }
}

private struct ControlsRow: View {
    let state: ReadingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 10) {
            pauseOrResumeButton
            stopButton
            saveQuoteButton
        }
    }

    @ViewBuilder
    private var pauseOrResumeButton: some View {
        if state.phase == .paused {
            Button(intent: ResumeSessionIntent()) {
                ControlLabel(systemImage: "play.fill", title: "Resume", isPrimary: true)
            }
            .buttonStyle(.plain)
        } else {
            Button(intent: PauseSessionIntent()) {
                ControlLabel(systemImage: "pause.fill", title: "Pause", isPrimary: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var stopButton: some View {
        Button(intent: StopFromLockScreenIntent()) {
            ControlLabel(systemImage: "stop.fill", title: "Stop", isPrimary: false)
        }
        .buttonStyle(.plain)
    }

    private var saveQuoteButton: some View {
        Link(destination: URL(string: "com.mykhivanov.Craw://session/timer")!) {
            ControlLabel(systemImage: "quote.opening", title: "Quote", isPrimary: false)
        }
    }
}

private struct ControlLabel: View {
    let systemImage: String
    let title: String
    let isPrimary: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(isPrimary ? LiveActivityPalette.canvas : LiveActivityPalette.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(isPrimary ? LiveActivityPalette.rausch : LiveActivityPalette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TimerLabel: View {
    let state: ReadingActivityAttributes.ContentState

    var body: some View {
        if state.phase == .running, let lastResumeAt = state.lastResumeAt {
            let base = Date(timeIntervalSinceNow: -TimeInterval(state.accumulatedElapsedSeconds))
            let referenceStart = min(
                base,
                lastResumeAt.addingTimeInterval(-TimeInterval(state.accumulatedElapsedSeconds))
            )
            Text(timerInterval: referenceStart...Date.distantFuture, countsDown: false)
        } else {
            Text(formatted(state.accumulatedElapsedSeconds))
        }
    }

    private func formatted(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
