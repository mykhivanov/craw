import SwiftData
import SwiftUI

@main
struct CrawApp: App {
    let container: ModelContainer

    @State private var sessionEngine = SessionEngine()

    init() {
        container = CrawModelContainer.live()
        #if DEBUG
            if SampleData.isLaunchArgumentEnabled {
                SampleData.seedIfEmpty(into: ModelContext(container))
            }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionEngine)
        }
        .modelContainer(container)
    }
}
