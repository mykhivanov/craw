import SwiftData
import SwiftUI

struct RootView: View {
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
    }
}

#Preview {
    RootView()
        .modelContainer(CrawModelContainer.previewInMemory())
}
