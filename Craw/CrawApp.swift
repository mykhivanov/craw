import SwiftData
import SwiftUI

@main
struct CrawApp: App {
    let container: ModelContainer

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
        }
        .modelContainer(container)
    }
}
