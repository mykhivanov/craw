import SwiftData
import SwiftUI

struct SessionTimerView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingQuoteSheet = false
    @State private var showingThoughtSheet = false

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
            pageStepper
            Spacer()
            controls
            captureRow
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.canvas)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                engine.persistSnapshot()
            }
        }
        .sheet(isPresented: $showingQuoteSheet) { QuickAddQuoteSheet() }
        .sheet(isPresented: $showingThoughtSheet) { QuickAddThoughtSheet() }
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

    private var pageStepper: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Current page")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            HStack(spacing: Theme.Spacing.md) {
                stepperButton("minus") {
                    engine.setCurrentPage(engine.currentPage - 1)
                }
                Text("\(engine.currentPage)")
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                    .monospacedDigit()
                    .frame(minWidth: 64)
                stepperButton("plus") {
                    engine.setCurrentPage(engine.currentPage + 1)
                }
            }
            Text("of \(engine.book?.totalPages ?? 0)")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.mutedSoft)
        }
    }

    private func stepperButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
                .frame(width: 44, height: 44)
                .background(Theme.Palette.surfaceStrong, in: Circle())
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
                Text("Stop")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
        }
    }

    private var captureRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            captureButton("Add quote", system: "quote.opening") {
                showingQuoteSheet = true
            }
            captureButton("Add thought", system: "lightbulb") {
                showingThoughtSheet = true
            }
        }
    }

    private func captureButton(_ label: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: system)
                    .font(.system(size: 14, weight: .medium))
                Text(label)
                    .font(Theme.Typography.buttonSm)
            }
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Palette.surfaceSoft)
            .clipShape(Capsule())
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
