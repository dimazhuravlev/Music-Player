import Foundation

// MARK: - Track Data Manager
class TrackDataManager {
    static let shared = TrackDataManager()
    
    // Cache tracks to avoid recreating them every time
    private lazy var cachedTracks: [Track] = generateSampleTracks()
    
    private init() {}
    
    func getSampleTracks() -> [Track] {
        return cachedTracks
    }
    
    private func generateSampleTracks() -> [Track] {
        return [
            // Original demo tracks
            Track(id: 1, title: "Taste", artist: "Uglymoss", albumCover: "blur", releaseYear: 2023),
            Track(id: 2, title: "Blueprint", artist: "Uglymoss", albumCover: "amputechture", releaseYear: 2024),
            Track(id: 3, title: "My Valuable Hunting Knife", artist: "Uglymoss", albumCover: "garlands", releaseYear: 2023),
            Track(id: 4, title: "أغنية أغنية ", artist: "Blur", albumCover: "cure", releaseYear: 1997),
            Track(id: 5, title: "الجمعة أنا в الحب الجمعة أنا в الحب", artist: "The Cure", albumCover: "aquarium", releaseYear: 1992),
            Track(id: 6, title: "الاعتدال الاعتدال", artist: "Aquarium", albumCover: "grob", releaseYear: 1998),
            Track(id: 7, title: "Teen Age Riot", artist: "Uglymoss", albumCover: "in rainbows", releaseYear: 1975),
            Track(id: 8, title: "Reckoner", artist: "Uglymoss", albumCover: "blur", releaseYear: 1976),
            Track(id: 9, title: "Paranoid Android", artist: "Uglymoss", albumCover: "leisure", releaseYear: 1971),
            Track(id: 10, title: "Imagine", artist: "John Lennon", albumCover: "loveless", releaseYear: 1971),
            Track(id: 11, title: "Billie Jean", artist: "Michael Jackson", albumCover: "cure", releaseYear: 1982),
            Track(id: 12, title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumCover: "aquarium", releaseYear: 1987),
            Track(id: 13, title: "Smells Like Teen Spirit", artist: "Nirvana", albumCover: "munity", releaseYear: 1991),
            Track(id: 14, title: "Wonderwall", artist: "Oasis", albumCover: "mywar", releaseYear: 1995),
            Track(id: 15, title: "Creep", artist: "Radiohead", albumCover: "blur", releaseYear: 1992),
            Track(id: 16, title: "Losing My Religion", artist: "R.E.M.", albumCover: "snow day", releaseYear: 1991),
            Track(id: 17, title: "Black", artist: "Pearl Jam", albumCover: "To Bring You My Love", releaseYear: 1991),
            Track(id: 18, title: "Come As You Are", artist: "Nirvana", albumCover: "cure", releaseYear: 1991),
            Track(id: 19, title: "Alive", artist: "Pearl Jam", albumCover: "aquarium", releaseYear: 1991),
            Track(id: 20, title: "Jeremy", artist: "Pearl Jam", albumCover: "Bitches Brew", releaseYear: 1991),
            Track(id: 21, title: "Even Flow", artist: "Pearl Jam", albumCover: "Bitches Brew", releaseYear: 1991),
            
            // New tracks for each new album cover
            Track(id: 22, title: "Abraxas", artist: "Santana", albumCover: "abraxas", releaseYear: 1970),
            Track(id: 23, title: "Arabic Dreams", artist: "Various", albumCover: "arabic", releaseYear: 2024),
            Track(id: 24, title: "Music Has the Right to Children", artist: "Boards of Canada", albumCover: "boardsofcanada", releaseYear: 1998),
            Track(id: 25, title: "Born in the U.S.A.", artist: "Bruce Springsteen", albumCover: "born-in-the-usa", releaseYear: 1984),
            Track(id: 26, title: "Closer", artist: "Joy Division", albumCover: "closer-joy-division", releaseYear: 1980),
            Track(id: 27, title: "Corraption", artist: "Corraption", albumCover: "corraption", releaseYear: 2024),
            Track(id: 28, title: "Enema of the State", artist: "Blink-182", albumCover: "enema-of-the-state", releaseYear: 1999),
            Track(id: 29, title: "Going Blank Again", artist: "Ride", albumCover: "going-blank-again", releaseYear: 1992),
            Track(id: 30, title: "King's Record Shop", artist: "Rosanne Cash", albumCover: "kings-record-shop", releaseYear: 1987),
            Track(id: 31, title: "Lemonade", artist: "Beyoncé", albumCover: "lemonade", releaseYear: 2016),
            Track(id: 32, title: "Maggot Brain", artist: "Funkadelic", albumCover: "maggot-brain", releaseYear: 1971),
            Track(id: 33, title: "Master of Puppets", artist: "Metallica", albumCover: "master-of-puppets", releaseYear: 1986),
            Track(id: 34, title: "Minor Threat", artist: "Minor Threat", albumCover: "minor-threat", releaseYear: 1984),
            Track(id: 35, title: "OK Computer", artist: "Radiohead", albumCover: "ok-computer", releaseYear: 1997),
            Track(id: 36, title: "Our Love to Admire", artist: "Interpol", albumCover: "our-love-to-admire", releaseYear: 2007),
            Track(id: 37, title: "If Two Worlds Kiss", artist: "Pink Turns Blue", albumCover: "pinkturnsblue", releaseYear: 1987),
            Track(id: 38, title: "Psychocandy", artist: "The Jesus and Mary Chain", albumCover: "psychocandy", releaseYear: 1985),
            Track(id: 39, title: "Relationship of Command", artist: "At the Drive-In", albumCover: "relationshipofcommand", releaseYear: 2000),
            Track(id: 40, title: "Rites of Spring", artist: "Rites of Spring", albumCover: "rites-of-spring", releaseYear: 1985),
            Track(id: 41, title: "Sleep Well Beast", artist: "The National", albumCover: "sleep-well-beast", releaseYear: 2017),
            Track(id: 42, title: "SOS", artist: "SZA", albumCover: "sos", releaseYear: 2022),
            Track(id: 43, title: "Tapestry", artist: "Carole King", albumCover: "tapestry", releaseYear: 1971),
            Track(id: 44, title: "The Queen Is Dead", artist: "The Smiths", albumCover: "the-queen-is-dead", releaseYear: 1986),
            Track(id: 45, title: "Visions", artist: "Grimes", albumCover: "visions", releaseYear: 2012),
            Track(id: 46, title: "What's Going On", artist: "Marvin Gaye", albumCover: "whats-going-on", releaseYear: 1971),
            Track(id: 47, title: "Whitney Houston", artist: "Whitney Houston", albumCover: "whitney-houston", releaseYear: 1985),
            Track(id: 48, title: "Young, Gifted and Black", artist: "Aretha Franklin", albumCover: "young-gifted-and-black", releaseYear: 1972)
        ]
    }
}
