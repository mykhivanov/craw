import SwiftData
import SwiftUI

struct StatsTab: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: StatsViewModel = AppEnvironment.makeStatsViewModel()
    @State private var backfill: StatsBackfillStore = .init()
    @State private var path: [StatsRoute] = []
    @State private var showPaywall: Bool = false

    private var service: ReadingStatsService {
        AppEnvironment.readingStatsService
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Stats")
                .navigationDestination(for: StatsRoute.self) { route in
                    routeView(route)
                }
        }
        .onChange(of: subscriptionStore.isEntitled, initial: false) { _, isActive in
            if isActive {
                backfill.runIfNeeded(in: modelContext, subscriptionStore: subscriptionStore)
                viewModel.reload()
            } else if case .loaded = viewModel.state {
                // Entitlement revoked while page was open — clear so we don't show stale data.
                viewModel.selectPeriod(.month)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if subscriptionStore.isEntitled {
            StatsPageView(
                viewModel: viewModel,
                backfill: backfill,
                onTileTap: pushDetail,
                onMethodologyTap: pushMethodology
            )
            .task {
                backfill.runIfNeeded(in: modelContext, subscriptionStore: subscriptionStore)
            }
        } else {
            StatsPaywallGateView { showPaywall = true }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
        }
    }

    private func pushDetail(_ selection: StatTileSelection) {
        guard let bundle = viewModel.state.bundle else { return }
        path.append(.detail(selection, bundle.generatedAt))
    }

    private func pushMethodology() {
        path.append(.methodology)
    }

    @ViewBuilder
    private func routeView(_ route: StatsRoute) -> some View {
        switch route {
        case let .detail(selection, _):
            if let bundle = viewModel.state.bundle {
                StatTileDetailView(
                    selection: selection,
                    tile: selection.tile(from: bundle.tiles),
                    trendPoints: trendPoints(for: selection, in: bundle),
                    onMethodologyTap: pushMethodology
                )
            } else {
                Text("Loading…")
                    .foregroundStyle(Theme.Palette.muted)
            }
        case .methodology:
            MethodologyView(service: service)
        }
    }

    private func trendPoints(for selection: StatTileSelection, in bundle: StatsBundle) -> [TrendPoint] {
        switch selection {
        case .focusDifficulty:
            bundle.trends.focusDifficulty12w
        case .minutes:
            bundle.trends.minutesPerWeek12w
        case .comprehension:
            bundle.trends.comprehensionLast20
        default:
            []
        }
    }
}

enum StatsRoute: Hashable {
    case detail(StatTileSelection, Date)
    case methodology
}

private struct StatsPaywallGateView: View {
    let onSubscribeTap: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                StatsBlurredPreview()
                whyBlock
                ctaButton
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Palette.canvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Your reading, measured.")
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
            Text("Track focus, comprehension, and how you compare to other readers.")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var whyBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(perks, id: \.self) { perk in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Palette.rausch)
                    Text(perk)
                        .font(Theme.Typography.bodyMd)
                        .foregroundStyle(Theme.Palette.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Theme.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var ctaButton: some View {
        OnboardingPrimaryButton(title: "Unlock stats") {
            onSubscribeTap()
        }
    }

    private let perks: [String] = [
        "12 metrics across focus, habit, volume, and composition",
        "See where you rank — top % of readers, by metric",
        "Trend charts back to your first week"
    ]
}
