import Foundation

struct CurationCache {
    /// Bump this value whenever the cached data format or URL construction changes,
    /// so stale caches are automatically discarded on the next launch.
    private static let version = 4

    struct CachedData: Codable {
        let tracks: [Track]
        let albums: [AlbumCardItem]
        let releases: [NewReleaseData]
    }

    private struct VersionedCache: Codable {
        let version: Int
        let data: CachedData
    }

    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("deezer_curation.json")
    }

    func save(_ data: CachedData) {
        do {
            let versioned = VersionedCache(version: Self.version, data: data)
            let encoded = try JSONEncoder().encode(versioned)
            try encoded.write(to: cacheURL, options: .atomic)
        } catch {
            print("[CurationCache] Save failed: \(error)")
        }
    }

    func load() -> CachedData? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return nil }
        do {
            let raw = try Data(contentsOf: cacheURL)
            let versioned = try JSONDecoder().decode(VersionedCache.self, from: raw)
            guard versioned.version == Self.version else {
                clear()
                return nil
            }
            return versioned.data
        } catch {
            print("[CurationCache] Load failed: \(error)")
            clear()
            return nil
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}
