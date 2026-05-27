import SwiftData
import SwiftUI

struct ReadyToFocusView: View {
    @Environment(SessionEngine.self) private var engine

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: Theme.Spacing.lg)

            Image("readingpreview")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 360)
                .padding(.horizontal, Theme.Spacing.xl)
                .accessibilityHidden(true)

            Text("Focus time?")
                .font(Theme.Typography.onboardingHero)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
                .accessibilityLabel("Focus time?")

            Spacer(minLength: Theme.Spacing.lg)

            buttonRow
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas)
    }

    private var buttonRow: some View {
        HStack(spacing: Theme.Spacing.base) {
            Button {
                engine.cancelStaging()
            } label: {
                Text("Cancel")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.surfaceStrong)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .accessibilityLabel("Cancel reading session start")

            Button {
                engine.confirmStart()
            } label: {
                Text("Start session")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .accessibilityLabel("Start reading session")
        }
    }
}

#Preview {
    let container = CrawModelContainer.previewInMemory()
    let context = ModelContext(container)
    SampleData.seed(into: context)
    let descriptor = FetchDescriptor<Book>(predicate: BookLibraryReader.inProgressPredicate)
    let book = (try? context.fetch(descriptor))?.first
    let engine = SessionEngine()
    _ = book.map { engine.stage(book: $0) }
    return ReadyToFocusView()
        .modelContainer(container)
        .environment(engine)
}
