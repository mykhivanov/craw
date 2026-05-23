import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext

    @State private var pendingRestoration: PendingRestoration?
    @State private var showRestoration = false

    private let cache = ActiveSessionCache()

    private struct PendingRestoration {
        let snapshot: ActiveSessionSnapshot
        let book: Book
    }

    var body: some View {
        TabView {
            HomeTab()
                .tabItem { Label("Home", systemImage: "house.fill") }
            QuotesTab()
                .tabItem { Label("Quotes", systemImage: "quote.bubble.fill") }
            StatsTab()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            ProfileTab()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(Theme.Palette.rausch)
        .fullScreenCover(isPresented: sessionRunningBinding) {
            SessionTimerView()
        }
        .fullScreenCover(isPresented: postStopBinding) {
            PostSessionFlow()
        }
        .sheet(isPresented: $showRestoration) {
            if let pending = pendingRestoration {
                RestorationPromptView(
                    book: pending.book,
                    snapshot: pending.snapshot,
                    onResume: { handleResume(pending) },
                    onStopAndSave: { handleStopAndSave(pending) }
                )
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
            }
        }
        .task {
            checkForRestoration()
        }
    }

    private var sessionRunningBinding: Binding<Bool> {
        Binding(
            get: { engine.state == .running || engine.state == .paused },
            set: { _ in }
        )
    }

    private var postStopBinding: Binding<Bool> {
        Binding(
            get: { engine.state == .stopped || engine.state == .saving },
            set: { _ in }
        )
    }

    private func checkForRestoration() {
        guard engine.state == .idle else { return }
        guard let snapshot = cache.load() else { return }
        let bookID = snapshot.bookID
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.id == bookID }
        )
        guard let book = (try? modelContext.fetch(descriptor))?.first else {
            cache.clear()
            return
        }
        pendingRestoration = PendingRestoration(snapshot: snapshot, book: book)
        showRestoration = true
    }

    private func handleResume(_ pending: PendingRestoration) {
        engine.restore(from: pending.snapshot, book: pending.book)
        clearRestoration()
    }

    private func handleStopAndSave(_ pending: PendingRestoration) {
        engine.restore(from: pending.snapshot, book: pending.book)
        engine.stop()
        clearRestoration()
    }

    private func clearRestoration() {
        showRestoration = false
        pendingRestoration = nil
    }
}

#Preview {
    RootView()
        .modelContainer(CrawModelContainer.previewInMemory())
        .environment(SessionEngine())
}
