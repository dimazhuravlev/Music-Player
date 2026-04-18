import Foundation

/// Entity that can be shared (album or playlist) for the share overlay.
struct ShareableEntity {
    let title: String
    let subtitle: String?   // e.g. artist name
    let year: Int?
    let coverImageName: String
    let artistImageName: String?  // for avatar in card
    var coverImageURL: URL? = nil
    var artistImageURL: URL? = nil

    static func album(
        title: String,
        artistName: String,
        releaseYear: Int,
        coverImageName: String,
        artistImageName: String,
        coverImageURL: URL? = nil,
        artistImageURL: URL? = nil
    ) -> ShareableEntity {
        ShareableEntity(
            title: title,
            subtitle: artistName,
            year: releaseYear,
            coverImageName: coverImageName,
            artistImageName: artistImageName,
            coverImageURL: coverImageURL,
            artistImageURL: artistImageURL
        )
    }

    static func playlist(title: String, coverImageName: String, coverImageURL: URL? = nil) -> ShareableEntity {
        ShareableEntity(
            title: title,
            subtitle: nil,
            year: nil,
            coverImageName: coverImageName,
            artistImageName: nil,
            coverImageURL: coverImageURL
        )
    }
}
