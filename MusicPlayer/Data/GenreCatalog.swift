import Foundation

struct GenreDefinition: Equatable {
    let cardTitle: String
    let genre: String
    let artists: [String]
    let backgroundCover: String
    var deezerGenreId: Int? = nil
    var artistImageURLs: [URL]? = nil
    var backgroundCoverURL: URL? = nil
}

final class GenreCatalog {
    static let shared = GenreCatalog()
    let entries: [GenreDefinition]
    let fallback: GenreDefinition

    private init() {
        entries = [
            GenreDefinition(
                cardTitle: "Razor-Sharp Riffs",
                genre: "Post-Hardcore",
                artists: ["At The Drive-In", "Fugazi", "Refused", "Drive Like Jehu", "Unwound", "Shellac", "Quicksand", "Helmet", "Rites of Spring", "Embrace"],
                backgroundCover: "1"
            ),
            GenreDefinition(
                cardTitle: "Bleak and Beautiful",
                genre: "Post-Punk",
                artists: ["Joy Division", "Bauhaus", "Siouxsie and the Banshees", "The Fall", "Wire", "Gang of Four", "Television", "Killing Joke", "The Chameleons", "Echo and the Bunnymen"],
                backgroundCover: "2"
            ),
            GenreDefinition(
                cardTitle: "Wall of Sound",
                genre: "Shoegaze",
                artists: ["My Bloody Valentine", "Slowdive", "Ride", "Cocteau Twins", "Lush", "Chapterhouse", "Swervedriver", "Pale Saints", "A Place to Bury Strangers", "Nothing"],
                backgroundCover: "3"
            ),
            GenreDefinition(
                cardTitle: "Controlled Chaos",
                genre: "Noise Rock",
                artists: ["Sonic Youth", "Swans", "The Jesus Lizard", "Melvins", "Butthole Surfers", "Big Black", "Scratch Acid", "Unsane", "Brainiac", "Boredoms"],
                backgroundCover: "4"
            ),
            GenreDefinition(
                cardTitle: "Burn It Down",
                genre: "Hardcore Punk",
                artists: ["Black Flag", "Bad Brains", "Minor Threat", "Dead Kennedys", "Hüsker Dü", "Converge", "Dag Nasty", "The Mars Volta", "Nick Cave", "Suicide"],
                backgroundCover: "5"
            ),
            GenreDefinition(
                cardTitle: "Add Your Favorite Artists",
                genre: "Artist Selection",
                artists: [],
                backgroundCover: "6"
            ),
            GenreDefinition(
                cardTitle: "Endless Horizons",
                genre: "Post-Rock",
                artists: ["Godspeed You! Black Emperor", "Mogwai", "Slint", "Tortoise", "Explosions in the Sky", "Sigur Ros", "Bark Psychosis", "Talk Talk", "Mono", "Do Make Say Think"],
                backgroundCover: "7"
            ),
            GenreDefinition(
                cardTitle: "Motorik Dreams",
                genre: "Krautrock",
                artists: ["CAN", "Neu!", "Faust", "Tangerine Dream", "Cluster", "Popol Vuh", "Amon Düül II", "This Heat", "Radiohead", "King Crimson"],
                backgroundCover: "8"
            ),
            GenreDefinition(
                cardTitle: "Dark Anthems",
                genre: "Gothic Rock",
                artists: ["Bauhaus", "The Sisters of Mercy", "Siouxsie and the Banshees", "The Birthday Party", "Red Lorry Yellow Lorry", "Einstürzende Neubauten", "Tuxedomoon", "The Pop Group", "Pere Ubu", "Nick Cave"],
                backgroundCover: "9"
            ),
            GenreDefinition(
                cardTitle: "No Compromise",
                genre: "No Wave",
                artists: ["Sonic Youth", "Swans", "Glenn Branca", "DNA", "Mars", "Suicide", "Television", "The Jesus and Mary Chain", "A Place to Bury Strangers", "Interpol"],
                backgroundCover: "10"
            ),
            GenreDefinition(
                cardTitle: "British Melancholy",
                genre: "Britpop & Alt",
                artists: ["Blur", "The Smiths", "Pulp", "Suede", "Elastica", "The Verve", "Oasis", "The Stone Roses", "Happy Mondays", "Radiohead"],
                backgroundCover: "11"
            ),
            GenreDefinition(
                cardTitle: "Machine Music",
                genre: "IDM & Electronic",
                artists: ["Aphex Twin", "Autechre", "Boards of Canada", "Squarepusher", "CAN", "Tangerine Dream", "Cluster", "Neu!", "Faust", "Mogwai"],
                backgroundCover: "12"
            ),
            GenreDefinition(
                cardTitle: "Desert Frequencies",
                genre: "Arabic Jazz",
                artists: ["Anouar Brahem", "Dhafer Youssef", "Rabih Abou-Khalil", "Grazhdanskaya Oborona", "King Crimson", "The Fall", "Wire", "Gang of Four", "This Heat", "Bark Psychosis"],
                backgroundCover: "1"
            ),
        ]
        fallback = GenreDefinition(
            cardTitle: "Razor-Sharp Riffs",
            genre: "Post-Hardcore",
            artists: ["Fugazi", "At The Drive-In", "Refused", "Drive Like Jehu", "Unwound", "Shellac", "Quicksand", "Helmet", "Rites of Spring", "Embrace"],
            backgroundCover: "1"
        )
    }
}
