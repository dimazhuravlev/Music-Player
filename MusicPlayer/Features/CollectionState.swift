import Foundation
import SwiftUI

/// Keeps the two most recent liked covers for the Collection tab.
/// Persists to UserDefaults so covers survive cold starts.
final class CollectionState: ObservableObject {
    @Published private(set) var previousCover: String?
    @Published private(set) var previousCoverURL: URL?
    @Published private(set) var latestCover: String?
    @Published private(set) var latestCoverURL: URL?

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let previousCover = "collection_previousCover"
        static let previousCoverURL = "collection_previousCoverURL"
        static let latestCover = "collection_latestCover"
        static let latestCoverURL = "collection_latestCoverURL"
    }

    init() {
        previousCover = defaults.string(forKey: Keys.previousCover)
        previousCoverURL = defaults.url(forKey: Keys.previousCoverURL)
        latestCover = defaults.string(forKey: Keys.latestCover)
        latestCoverURL = defaults.url(forKey: Keys.latestCoverURL)
    }

    func registerLike(coverName: String, coverURL: URL? = nil) {
        guard !coverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        previousCover = latestCover
        previousCoverURL = latestCoverURL
        latestCover = coverName
        latestCoverURL = coverURL
        persist()
    }

    var hasCovers: Bool {
        previousCover != nil || latestCover != nil
    }

    private func persist() {
        defaults.set(previousCover, forKey: Keys.previousCover)
        defaults.set(previousCoverURL, forKey: Keys.previousCoverURL)
        defaults.set(latestCover, forKey: Keys.latestCover)
        defaults.set(latestCoverURL, forKey: Keys.latestCoverURL)
    }
}
