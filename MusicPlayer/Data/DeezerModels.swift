import Foundation

// MARK: - Generic Search Response

struct DeezerSearchResponse<T: Decodable>: Decodable {
    let data: [T]
    let total: Int?
    let next: String?
}

// MARK: - Genre

struct DeezerGenre: Decodable, Identifiable {
    let id: Int
    let name: String
    let picture: String?
    let pictureMedium: String?
    let pictureBig: String?
}

struct DeezerGenreListResponse: Decodable {
    let data: [DeezerGenre]
}

// MARK: - Artist

struct DeezerArtistBrief: Decodable, Identifiable {
    let id: Int
    let name: String
    let picture: String?
    let pictureSmall: String?
    let pictureMedium: String?
    let pictureBig: String?
    let pictureXl: String?
    let tracklist: String?
}

struct DeezerArtist: Decodable, Identifiable {
    let id: Int
    let name: String
    let link: String?
    let picture: String?
    let pictureSmall: String?
    let pictureMedium: String?
    let pictureBig: String?
    let pictureXl: String?
    let nbAlbum: Int?
    let nbFan: Int?
    let tracklist: String?
}

// MARK: - Playlist

struct DeezerPlaylistCreator: Decodable {
    let name: String?
}

/// Метаданные плейлиста (`GET /playlist/:id`) — обложка и название для каруселей.
struct DeezerPlaylist: Decodable, Identifiable {
    let id: Int
    let title: String
    let pictureBig: String?
    let pictureXl: String?
    let creator: DeezerPlaylistCreator?
}

// MARK: - Album

struct DeezerAlbumBrief: Decodable, Identifiable {
    let id: Int
    let title: String
    /// Основной жанр релиза в каталоге Deezer (`/artist/.../albums` отдаёт поле `genre_id`).
    let genreId: Int?
    let cover: String?
    let coverSmall: String?
    let coverMedium: String?
    let coverBig: String?
    let coverXl: String?
    let tracklist: String?
}

struct DeezerAlbum: Decodable, Identifiable {
    let id: Int
    let title: String
    let upc: String?
    let link: String?
    let cover: String?
    let coverSmall: String?
    let coverMedium: String?
    let coverBig: String?
    let coverXl: String?
    let genreId: Int?
    let genres: DeezerGenreListResponse?
    let label: String?
    let nbTracks: Int?
    let duration: Int?
    let fans: Int?
    let releaseDate: String?
    let recordType: String?
    let explicitLyrics: Bool?
    let tracklist: String?
    let artist: DeezerArtistBrief?
    let tracks: DeezerTrackListResponse?

    var releaseYear: Int? {
        guard let dateStr = releaseDate else { return nil }
        let parts = dateStr.split(separator: "-")
        guard let yearStr = parts.first else { return nil }
        return Int(yearStr)
    }
}

// MARK: - Track

struct DeezerTrackResult: Decodable, Identifiable {
    let id: Int
    let title: String
    let titleShort: String?
    let duration: Int?
    let rank: Int?
    let explicitLyrics: Bool?
    let preview: String?
    let artist: DeezerArtistBrief?
    let album: DeezerAlbumBrief?
    let trackPosition: Int?
    let diskNumber: Int?
}

struct DeezerTrackListResponse: Decodable {
    let data: [DeezerTrackResult]
}

// MARK: - Search Result Aliases (for /search/album, /search/artist)

typealias DeezerAlbumSearchResult = DeezerAlbumBrief
typealias DeezerArtistSearchResult = DeezerArtistBrief

// MARK: - Album search result (has nested artist)

struct DeezerAlbumSearchItem: Decodable, Identifiable {
    let id: Int
    let title: String
    let cover: String?
    let coverSmall: String?
    let coverMedium: String?
    let coverBig: String?
    let coverXl: String?
    let genreId: Int?
    let nbTracks: Int?
    let recordType: String?
    let tracklist: String?
    let explicitLyrics: Bool?
    let artist: DeezerArtistBrief?
}
