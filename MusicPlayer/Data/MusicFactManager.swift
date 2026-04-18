import Foundation
import SwiftUI

final class MusicFactManager: ObservableObject {
    @Published var currentFact: String?
    @Published var isLoading = false

    private var memoryCache: [String: String] = [:]
    private var currentTask: Task<Void, Never>?
    private let diskCacheKey = "music_fact_cache"

    /// Called when the user taps a cover to play a new track.
    /// Fires an API request only if no cached fact exists for this track.
    func triggerPlay(for track: Track) {
        let key = factKey(for: track)

        if let fact = cachedFact(forKey: key) {
            currentTask?.cancel()
            currentFact = fact
            isLoading = false
            return
        }

        currentTask?.cancel()
        currentFact = nil
        isLoading = true

        currentTask = Task { @MainActor in
            do {
                let fact = try await OpenAIService.shared.generateFact(for: track)
                guard !Task.isCancelled else { return }
                self.saveFact(fact, forKey: key)
                self.currentFact = fact
            } catch {
                guard !Task.isCancelled else { return }
                self.currentFact = nil
            }
            self.isLoading = false
        }
    }

    /// Called on swipe or player appear — reads from cache only, never fires API.
    func showCachedFact(for track: Track) {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
        currentFact = cachedFact(forKey: factKey(for: track))
    }

    // MARK: - Cache

    private func factKey(for track: Track) -> String {
        "\(track.title)_\(track.artist)"
    }

    private func cachedFact(forKey key: String) -> String? {
        if let mem = memoryCache[key] { return mem }
        let disk = loadDiskCache()
        if let fact = disk[key] {
            memoryCache[key] = fact
            return fact
        }
        return nil
    }

    private func saveFact(_ fact: String, forKey key: String) {
        memoryCache[key] = fact
        var disk = loadDiskCache()
        disk[key] = fact
        saveDiskCache(disk)
    }

    private func loadDiskCache() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: diskCacheKey),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return dict
    }

    private func saveDiskCache(_ dict: [String: String]) {
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: diskCacheKey)
        }
    }
}
