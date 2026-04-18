import Foundation

// MARK: - Errors

enum DeezerError: Error, LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(Error)
    case rateLimited
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Deezer API URL"
        case .httpError(let code): return "HTTP error \(code)"
        case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        case .rateLimited: return "Rate limit exceeded"
        case .noData: return "No data returned"
        }
    }
}

// MARK: - Service

actor DeezerService {
    static let shared = DeezerService()

    private let baseURL = "https://api.deezer.com"
    private let session: URLSession
    private let decoder: JSONDecoder

    // Rate limiting: track request timestamps
    private var requestTimestamps: [Date] = []
    private let maxRequestsPer5Seconds = 50
    private let minRequestInterval: TimeInterval = 0.11 // ~9 req/s max

    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,  // 20 MB memory
            diskCapacity: 100 * 1024 * 1024,    // 100 MB disk
            diskPath: "deezer_cache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = dec
    }

    // MARK: - Public API

    func searchAlbums(query: String, limit: Int = 25) async throws -> [DeezerAlbumSearchItem] {
        let response: DeezerSearchResponse<DeezerAlbumSearchItem> = try await fetch(
            path: "/search/album",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return response.data
    }

    func searchArtists(query: String, limit: Int = 25) async throws -> [DeezerArtistBrief] {
        let response: DeezerSearchResponse<DeezerArtistBrief> = try await fetch(
            path: "/search/artist",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return response.data
    }

    func searchTracks(query: String, limit: Int = 25) async throws -> [DeezerTrackResult] {
        let response: DeezerSearchResponse<DeezerTrackResult> = try await fetch(
            path: "/search/track",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return response.data
    }

    func getAlbum(id: Int) async throws -> DeezerAlbum {
        return try await fetch(path: "/album/\(id)")
    }

    func getArtist(id: Int) async throws -> DeezerArtist {
        return try await fetch(path: "/artist/\(id)")
    }

    func getArtistAlbums(id: Int, limit: Int = 25, index: Int = 0) async throws -> [DeezerAlbumBrief] {
        let response: DeezerSearchResponse<DeezerAlbumBrief> = try await fetch(
            path: "/artist/\(id)/albums",
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "index", value: "\(index)"),
            ]
        )
        return response.data
    }

    func getAlbumTracks(id: Int) async throws -> [DeezerTrackResult] {
        let response: DeezerSearchResponse<DeezerTrackResult> = try await fetch(
            path: "/album/\(id)/tracks",
            queryItems: [URLQueryItem(name: "limit", value: "100")]
        )
        return response.data
    }

    func getGenres() async throws -> [DeezerGenre] {
        let response: DeezerGenreListResponse = try await fetch(path: "/genre")
        return response.data
    }

    func getGenreArtists(genreId: Int, limit: Int = 25, index: Int = 0) async throws -> [DeezerArtistBrief] {
        let response: DeezerSearchResponse<DeezerArtistBrief> = try await fetch(
            path: "/genre/\(genreId)/artists",
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "index", value: "\(index)"),
            ]
        )
        return response.data
    }

    /// Треки плейлиста (по id плейлиста; выдача не привязана к региону клиента так же сильно, как `genre/.../artists`).
    func getPlaylistTracks(playlistId: Int, limit: Int = 50, index: Int = 0) async throws -> [DeezerTrackResult] {
        let response: DeezerSearchResponse<DeezerTrackResult> = try await fetch(
            path: "/playlist/\(playlistId)/tracks",
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "index", value: "\(index)"),
            ]
        )
        return response.data
    }

    func getPlaylist(id: Int) async throws -> DeezerPlaylist {
        try await fetch(path: "/playlist/\(id)")
    }

    /// Глобальный чарт (id `0` — без фильтра по жанру/региону в каталоге Deezer).
    func getChartTracks(limit: Int = 50, index: Int = 0) async throws -> [DeezerTrackResult] {
        let response: DeezerSearchResponse<DeezerTrackResult> = try await fetch(
            path: "/chart/0/tracks",
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "index", value: "\(index)")
            ]
        )
        return response.data
    }

    func getChartAlbums(limit: Int = 50, index: Int = 0) async throws -> [DeezerAlbumSearchItem] {
        let response: DeezerSearchResponse<DeezerAlbumSearchItem> = try await fetch(
            path: "/chart/0/albums",
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "index", value: "\(index)")
            ]
        )
        return response.data
    }

    // MARK: - Private

    private func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        await throttle()

        var components = URLComponents(string: baseURL + path)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw DeezerError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        // Чарты и плейлисты меняются; иначе кэш отдаёт устаревший срез.
        if path.contains("/chart/") || path.contains("/playlist/") {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 {
                throw DeezerError.rateLimited
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw DeezerError.httpError(statusCode: httpResponse.statusCode)
            }
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DeezerError.decodingError(error)
        }
    }

    private func throttle() async {
        let now = Date()
        requestTimestamps.removeAll { now.timeIntervalSince($0) > 5 }

        if requestTimestamps.count >= maxRequestsPer5Seconds {
            try? await Task.sleep(nanoseconds: UInt64(1.0 * 1_000_000_000))
            requestTimestamps.removeAll { Date().timeIntervalSince($0) > 5 }
        }

        requestTimestamps.append(Date())
    }
}
