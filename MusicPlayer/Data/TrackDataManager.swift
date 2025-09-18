import Foundation

// MARK: - Track Data Manager
class TrackDataManager {
    static let shared = TrackDataManager()
    
    private init() {}
    
    func getSampleTracks() -> [Track] {
        return [
            Track(id: 1, title: "Taste", artist: "Uglymoss", albumCover: "blur", releaseYear: 2023),
            Track(id: 2, title: "Blueprint", artist: "Uglymoss", albumCover: "benson", releaseYear: 2024),
            Track(id: 3, title: "My Valuable Hunting Knife", artist: "Uglymoss", albumCover: "love letters", releaseYear: 2023),
            Track(id: 4, title: "Song 2", artist: "Blur", albumCover: "cure", releaseYear: 1997),
            Track(id: 5, title: "Friday I'm in Love", artist: "The Cure", albumCover: "aquarium", releaseYear: 1992),
            Track(id: 6, title: "Equinox", artist: "Aquarium", albumCover: "sonic", releaseYear: 1998),
            Track(id: 7, title: "Sonic Youth", artist: "Uglymoss", albumCover: "uglymoss", releaseYear: 1975),
            Track(id: 8, title: "Uglymoss Track", artist: "Uglymoss", albumCover: "blur", releaseYear: 1976),
            Track(id: 9, title: "Another Track", artist: "Uglymoss", albumCover: "benson", releaseYear: 1971),
            Track(id: 10, title: "Imagine", artist: "John Lennon", albumCover: "love letters", releaseYear: 1971),
            Track(id: 11, title: "Billie Jean", artist: "Michael Jackson", albumCover: "cure", releaseYear: 1982),
            Track(id: 12, title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumCover: "aquarium", releaseYear: 1987),
            Track(id: 13, title: "Smells Like Teen Spirit", artist: "Nirvana", albumCover: "sonic", releaseYear: 1991),
            Track(id: 14, title: "Wonderwall", artist: "Oasis", albumCover: "uglymoss", releaseYear: 1995),
            Track(id: 15, title: "Creep", artist: "Radiohead", albumCover: "blur", releaseYear: 1992),
            Track(id: 16, title: "Losing My Religion", artist: "R.E.M.", albumCover: "benson", releaseYear: 1991),
            Track(id: 17, title: "Black", artist: "Pearl Jam", albumCover: "love letters", releaseYear: 1991),
            Track(id: 18, title: "Come As You Are", artist: "Nirvana", albumCover: "cure", releaseYear: 1991),
            Track(id: 19, title: "Alive", artist: "Pearl Jam", albumCover: "aquarium", releaseYear: 1991),
            Track(id: 20, title: "Jeremy", artist: "Pearl Jam", albumCover: "sonic", releaseYear: 1991),
            Track(id: 21, title: "Even Flow", artist: "Pearl Jam", albumCover: "uglymoss", releaseYear: 1991)
        ]
    }
}
