import SwiftUI

struct HomeTab: View {
    @Environment(SessionEngine.self) private var engine
    @State private var path: [HomeRoute] = []

    private enum HomeRoute: Hashable {
        case allCurrentlyReading
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeDashboardView(
                onStartSession: startSession,
                onShowAllCurrentlyReading: {
                    path.append(.allCurrentlyReading)
                }
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .allCurrentlyReading:
                    AllCurrentlyReadingListView(onStart: startSession)
                }
            }
        }
    }

    private func startSession(_ book: Book) {
        engine.start(book: book)
    }
}
