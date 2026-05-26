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

    private enum CoverContent: Identifiable {
        case timer
        case post
        var id: Self {
            self
        }
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
        .fullScreenCover(item: coverBinding) { content in
            switch content {
            case .timer: SessionTimerView()
            case .post: PostSessionFlow()
            }
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

    private var coverBinding: Binding<CoverContent?> {
        Binding(
            get: {
                let content: CoverContent? = switch engine.state {
                case .running, .paused: .timer
                case .stopped, .saving: .post
                case .idle: nil
                }
                return content
            },
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
