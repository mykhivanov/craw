import Foundation
import Testing
@testable import Craw

@MainActor
@Suite("SessionEngine")
struct SessionEngineTests {
    private final class SpyCache: ActiveSessionCaching {
        var saved: [ActiveSessionSnapshot] = []
        var loaded: ActiveSessionSnapshot?
        var clearCount = 0

        func save(_ snapshot: ActiveSessionSnapshot) {
            saved.append(snapshot)
        }

        func load() -> ActiveSessionSnapshot? {
            loaded
        }

        func clear() {
            clearCount += 1
        }
    }

    private func makeBook(totalPages: Int = 300) -> Book {
        Book(title: "Sample", author: "Author", totalPages: totalPages, attitude: .study)
    }

    @Test("Start → stop reports correct elapsed seconds")
    func startStop() {
        let cache = SpyCache()
        let engine = SessionEngine(cache: cache)
        let book = makeBook()
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        let t1 = t0.addingTimeInterval(20 * 60)

        engine.start(book: book, now: t0)
        engine.stop(now: t1)

        #expect(engine.state == .stopped)
        #expect(engine.elapsedSeconds == 20 * 60)
        #expect(engine.endedAsBookFinished == false)
    }

    @Test("Pause/resume excludes paused time from elapsedSeconds")
    func pauseResumeExcludesGap() {
        let cache = SpyCache()
        let engine = SessionEngine(cache: cache)
        let book = makeBook()
        let t0 = Date(timeIntervalSince1970: 2_000_000)
        let t1 = t0.addingTimeInterval(300) // ran 5 min
        let t2 = t1.addingTimeInterval(600) // paused 10 min
        let t3 = t2.addingTimeInterval(300) // ran 5 more min

        engine.start(book: book, now: t0)
        engine.pause(now: t1)
        engine.resume(now: t2)
        engine.stop(now: t3)

        #expect(engine.elapsedSeconds == 600) // 5 + 5 minutes
    }

    @Test("Stop from paused works")
    func stopFromPaused() {
        let cache = SpyCache()
        let engine = SessionEngine(cache: cache)
        let book = makeBook()
        let t0 = Date(timeIntervalSince1970: 3_000_000)
        let t1 = t0.addingTimeInterval(120)

        engine.start(book: book, now: t0)
        engine.pause(now: t1)
        engine.stop(now: t1.addingTimeInterval(10)) // stop while paused, no time should be added

        #expect(engine.state == .stopped)
        #expect(engine.elapsedSeconds == 120)
    }

    @Test("Stop with asBookFinished flag is recorded on the engine")
    func stopAsBookFinishedFlag() {
        let cache = SpyCache()
        let engine = SessionEngine(cache: cache)
        let book = makeBook()
        engine.start(book: book)
        engine.stop(asBookFinished: true)
        #expect(engine.endedAsBookFinished == true)
    }

    @Test("Every state transition writes a snapshot")
    func snapshotOnEveryTransition() {
        let cache = SpyCache()
        let engine = SessionEngine(cache: cache)
        let book = makeBook()
        let t0 = Date(timeIntervalSince1970: 4_000_000)

        engine.start(book: book, now: t0)
        let afterStart = cache.saved.count

        engine.pause(now: t0.addingTimeInterval(60))
        engine.resume(now: t0.addingTimeInterval(120))
        engine.stop(now: t0.addingTimeInterval(180))

        #expect(afterStart >= 1)
        #expect(cache.saved.count >= 4) // start + pause + resume + stop
    }

    @Test("finish() clears cache and resets to idle")
    func finishResets() {
        let cache = SpyCache()
        let engine = SessionEngine(cache: cache)
        engine.start(book: makeBook())
        engine.stop()
        engine.beginSaving()
        engine.finish()
        #expect(engine.state == .idle)
        #expect(engine.book == nil)
        #expect(engine.endedAsBookFinished == false)
        #expect(cache.clearCount == 1)
    }

    @Test("Restore from running snapshot preserves accumulated time")
    func restoreRunning() {
        let cache = SpyCache()
        let engine = SessionEngine(cache: cache)
        let book = makeBook(totalPages: 400)
        let snapshot = ActiveSessionSnapshot(
            bookID: book.id,
            startedAt: Date(timeIntervalSince1970: 5_000_000),
            accumulatedElapsedSeconds: 450,
            isPaused: false,
            lastCheckpointAt: Date(timeIntervalSince1970: 5_000_450)
        )
        engine.restore(from: snapshot, book: book, now: Date(timeIntervalSince1970: 5_100_000))
        #expect(engine.state == .running)
        #expect(engine.accumulatedElapsedSeconds == 450)
    }
}
