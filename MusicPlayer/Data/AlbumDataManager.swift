import Foundation

// MARK: - Album Data Models
struct AlbumData {
    let albumImageName: String
    let artistImageName: String
    let artistName: String
    let releaseYear: Int
    let artistBio: String
    var albumImageURL: URL? = nil
    var artistImageURL: URL? = nil
    var artistThumbnailURL: URL? = nil
    var deezerAlbumId: Int? = nil
    var tracks: [Track]? = nil
}

// MARK: - Album Data Manager
class AlbumDataManager {
    static let shared = AlbumDataManager()

    private init() {}

    func getAlbumData(for albumName: String?) -> AlbumData {
        return AlbumData(
            albumImageName: "album",
            artistImageName: "userpic",
            artistName: albumName ?? "Artist",
            releaseYear: 2024,
            artistBio: ""
        )
    }
}
