import Foundation

// MARK: - Track Data Manager
@MainActor
class TrackDataManager {
    static let shared = TrackDataManager()

    private init() {}

    func getSampleTracks() -> [Track] {
        return ContentCurationManager.shared.curatedTracks
    }
}
