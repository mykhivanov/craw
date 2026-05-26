import SwiftData
import SwiftUI

struct SessionTimerView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State private var showingQuoteSheet = false
    @State private var confirmingBookFinished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            header
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                VStack(spacing: Theme.Spacing.sm) {
                    Text(formatted(engine.elapsedSeconds))
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.ink)
                    Text(engine.state == .paused ? "Paused" : "Reading")
                        .font(Theme.Typography.captionSm)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }
            Spacer()
            captureRow
            controls
            bookFinishedButton
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.canvas)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                engine.persistSnapshot()
            }
        }
        .sheet(isPresented: $showingQuoteSheet) { QuickAddQuoteSheet() }
        .confirmationDialog(
            "Mark this book as finished?",
            isPresented: $confirmingBookFinished,
            titleVisibility: .visible
        ) {
            Button("Yes, finish", role: .destructive) {
                finishBookAndStopSession()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The session will end and the book will move to your Finished list.")
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text(engine.book?.title ?? "")
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
            Text(engine.book?.author ?? "")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private var controls: some View {
        HStack(spacing: Theme.Spacing.base) {
            Button {
                if engine.state == .running {
                    engine.pause()
                } else {
                    engine.resume()
                }
            } label: {
                Text(engine.state == .running ? "Pause" : "Resume")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.surfaceStrong)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            Button {
                engine.stop()
            } label: {
                Text("Finish")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
        }
    }

    private var bookFinishedButton: some View {
        Button {
            confirmingBookFinished = true
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 14, weight: .medium))
                Text("Book is finished")
                    .font(Theme.Typography.buttonSm)
            }
            .foregroundStyle(Theme.Palette.muted)
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Palette.surfaceSoft)
            .clipShape(Capsule())
        }
    }

    private var captureRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                showingQuoteSheet = true
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14, weight: .medium))
                    Text("Add quote")
                        .font(Theme.Typography.buttonSm)
                }
                .foregroundStyle(Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.base)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Palette.surfaceSoft)
                .clipShape(Capsule())
            }
        }
    }

    private func finishBookAndStopSession() {
        guard let bookID = engine.book?.id else {
            engine.stop(asBookFinished: true)
            return
        }
        let pipeline = PostSessionPipeline(context: modelContext)
        pipeline.markBookFinished(bookID: bookID)
        engine.stop(asBookFinished: true)
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
