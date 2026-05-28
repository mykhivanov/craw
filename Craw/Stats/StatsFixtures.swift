#if DEBUG
    import Foundation

    enum StatsFixtures {
        static func bundle(for period: StatsPeriod) -> StatsBundle {
            StatsBundle(
                period: period,
                generatedAt: .now,
                tiles: defaultTiles(),
                trends: defaultTrends()
            )
        }

        private static func defaultTiles() -> TileSet {
            TileSet(
                focusDifficulty: tile(value: 2.4, unit: "/ 5", priorValue: 2.8, percentile: 82, median: 3.1),
                goalHitRate: tile(value: 82, unit: "%", priorValue: 74, percentile: 78, median: 54),
                comprehension: tile(value: 78, unit: "%", priorValue: 72, percentile: 75, median: 65),
                avgSessionMin: tile(value: 28, unit: "min", priorValue: 24, percentile: 70, median: 19),
                sessionsPerWeek: tile(value: 5.2, unit: "/ wk", priorValue: 4.6, percentile: 85, median: 3.1),
                currentStreak: tile(value: 17, unit: "days", priorValue: 5, percentile: 88, median: 4),
                fullWeekStreaks: tile(value: 8, unit: "wks", priorValue: 6, percentile: 86, median: 2),
                minutes: tile(value: 1247, unit: "min", priorValue: 1056, percentile: 86, median: 540),
                booksFinished: tile(value: 7, unit: "books", priorValue: 5, percentile: 78, median: 3),
                sessionsTotal: tile(value: 42, unit: "sess.", priorValue: 36, percentile: 80, median: 18),
                studyShare: tile(value: 60, unit: "%", priorValue: 52, percentile: 72, median: 38),
                finishRate: tile(value: 73, unit: "%", priorValue: 68, percentile: 65, median: 55)
            )
        }

        private static func tile(
            value: Double?,
            unit: String,
            priorValue: Double?,
            percentile: Int,
            median: Double
        ) -> Tile {
            let trend: TileTrend? = {
                guard let value, let priorValue else { return nil }
                let delta = value - priorValue
                let pct = priorValue == 0 ? nil : (delta / priorValue) * 100
                return TileTrend(priorValue: priorValue, delta: delta, deltaPct: pct)
            }()
            return Tile(
                value: value,
                unit: unit,
                trend: trend,
                cohort: TileCohort(percentile: percentile, median: median, source: "synthetic_v1")
            )
        }

        private static func defaultTrends() -> TrendSet {
            TrendSet(
                focusDifficulty12w: sparkline(
                    values: [3.8, 3.6, 3.4, 3.5, 3.2, 3.1, 2.9, 2.8, 2.7, 2.6, 2.5, 2.4],
                    unit: 7
                ),
                minutesPerWeek12w: sparkline(
                    values: [120, 140, 160, 150, 180, 200, 210, 230, 220, 250, 270, 290],
                    unit: 7
                ),
                comprehensionLast20: sparkline(
                    values: [62, 65, 60, 70, 72, 68, 74, 76, 73, 78, 75, 80, 77, 79, 82, 78, 81, 84, 79, 83],
                    unit: 1
                )
            )
        }

        private static func sparkline(values: [Double], unit: Int) -> [TrendPoint] {
            let calendar = Calendar.autoupdatingCurrent
            let today = calendar.startOfDay(for: .now)
            return values.enumerated().compactMap { offset, value in
                let daysBack = (values.count - 1 - offset) * unit
                guard let date = calendar.date(byAdding: .day, value: -daysBack, to: today) else { return nil }
                return TrendPoint(at: date, value: value)
            }
        }

        static let methodology: String = """
        # How we compare you

        Your stats blend two data sources:

        - **Reading research** — published findings from Pew Research, the U.S. Bureau of
          Labor Statistics' American Time Use Survey, and habit-formation literature.
        - **Anonymous Craw aggregates** — the same metrics, computed across all paying
          Craw readers. As more readers join, this share grows.

        We tell you "Top 22% of readers" rather than "Top 22% of Craw users" because the
        comparison cohort is intentionally broader than just the app. Two metrics — focus
        difficulty and comprehension — have no public reference distribution, so the
        baseline for those is calibrated entirely from Craw readers as data accumulates.

        Comparisons exclude users with no data for a given metric.
        """
    }
#endif
