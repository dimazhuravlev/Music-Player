import Foundation

struct GenreDefinition: Equatable {
    let cardTitle: String
    let genre: String
    let artists: [String]
    let backgroundCover: String
}

final class GenreCatalog {
    static let shared = GenreCatalog()
    let entries: [GenreDefinition]
    let fallback: GenreDefinition
    
    private init() {
        entries = [
            GenreDefinition(
                cardTitle: "Futuristic Beats Chasers",
                genre: "Electronic",
                artists: [
                    "Marshmello",
                    "David Guetta",
                    "Tiësto",
                    "Alan Walker",
                    "Calvin Harris",
                    "Avicii",
                    "The Chainsmokers",
                    "Kygo",
                    "Zedd",
                    "Martin Garrix"
                ],
                backgroundCover: "1"
            ),
            GenreDefinition(
                cardTitle: "El Scene Lovers",
                genre: "Egyptian Hip-Hop",
                artists: [
                    "Wegz 1",
                    "Marwan Moussa",
                    "Lege-Cy",
                    "Shehab",
                    "Marwan Pablo",
                    "3froto",
                    "Molotof",
                    "Abo El Anwar",
                    "Sharmoofers",
                    "Abyusif"
                ],
                backgroundCover: "2"
            ),
            GenreDefinition(
                cardTitle: "Nile Romantic",
                genre: "Egyptian Pop",
                artists: [
                    "Amr Diab",
                    "Tamer Ashour",
                    "Ramy Sabry",
                    "Tamer Hosny",
                    "Mohamed Hamaki",
                    "Sherine",
                    "Angham",
                    "Ahmed Saad",
                    "Ramy Gamal",
                    "Bahaa Sultan"
                ],
                backgroundCover: "3"
            ),
            GenreDefinition(
                cardTitle: "Sacred Soul Journey",
                genre: "Spiritual",
                artists: [
                    "Abdul Rahman Al Sudais",
                    "Mishary Rashid Alafasy",
                    "Saad Al Ghamdi",
                    "Abdul Basit Abdul Samad",
                    "Muhammad Al Muqit",
                    "Fares Abbad",
                    "Abdullah Al Matrood",
                    "Muhammad Ayyub",
                    "Abdul Aziz Al Ahmad",
                    "Muhammad Al Luhaidan"
                ],
                backgroundCover: "4"
            ),
            GenreDefinition(
                cardTitle: "The Gangnam Style",
                genre: "K-Pop",
                artists: [
                    "BTS",
                    "BLACKPINK",
                    "Stray Kids",
                    "Jungkook",
                    "j-hope",
                    "EXO",
                    "TWICE",
                    "The Rose",
                    "ITZY",
                    "IVE"
                ],
                backgroundCover: "5"
            ),
            GenreDefinition(
                cardTitle: "Add Your Favorite Artists",
                genre: "Artist Selection",
                artists: [],
                backgroundCover: "6"
            ),
            GenreDefinition(
                cardTitle: "World's Hits Collector",
                genre: "International Pop",
                artists: [
                    "Billie Eilish",
                    "Coldplay",
                    "Lady Gaga",
                    "Ariana Grande",
                    "Ed Sheeran",
                    "Lana Del Rey",
                    "Adele",
                    "Imagine Dragons",
                    "Selena Gomez",
                    "Bruno Mars"
                ],
                backgroundCover: "7"
            ),
            GenreDefinition(
                cardTitle: "Shami Mood",
                genre: "Levant Pop",
                artists: [
                    "Elissa",
                    "Assala Nasri",
                    "Nassif Zeytoun",
                    "Al Shami",
                    "Nancy Ajram",
                    "Fadel Chaker",
                    "Wael Jassar",
                    "Carole Samaha",
                    "Wael Kfoury",
                    "Fairuz"
                ],
                backgroundCover: "8"
            ),
            GenreDefinition(
                cardTitle: "Rebellious Streetlife Energy",
                genre: "International Hip-Hop",
                artists: [
                    "Drake",
                    "Travis Scott",
                    "Post Malone",
                    "Kendrick Lamar",
                    "Kanye West",
                    "Eminem",
                    "Nicky Minaj",
                    "Lil Nas X",
                    "Doja Cat",
                    "21 Savage"
                ],
                backgroundCover: "9"
            ),
            GenreDefinition(
                cardTitle: "Rouh Al Khaleej",
                genre: "Khaleeji Pop",
                artists: [
                    "Ahlam",
                    "Rashed Al-Majed",
                    "Hussain Al Jassmi",
                    "Nawal",
                    "Abdul Majeed Abdullah",
                    "Majid Al Mohandes",
                    "Balqees",
                    "Nabeel Shuail",
                    "Rabeh Saqer",
                    "Ayed"
                ],
                backgroundCover: "10"
            ),
            GenreDefinition(
                cardTitle: "Nabd El Share3",
                genre: "Levant Hip-Hop",
                artists: [
                    "The Synaptik",
                    "Shabjdeed",
                    "El Rass",
                    "Bu Kolthoum",
                    "Tamer Nafar",
                    "DAM",
                    "Blu Fiefer",
                    "Autostrad",
                    "El Far3i",
                    "47 Soul"
                ],
                backgroundCover: "11"
            ),
            GenreDefinition(
                cardTitle: "MC Maghreb Khouya",
                genre: "Moroccan Hip-Hop",
                artists: [
                    "Elgrandetoto",
                    "Don Bigg",
                    "Dizzy DROS",
                    "LFERDA",
                    "Tagne",
                    "Stormy",
                    "Lbenj",
                    "7-TOUN",
                    "Mr Draganov",
                    "Muslim"
                ],
                backgroundCover: "12"
            ),
            GenreDefinition(
                cardTitle: "The Modern Swagger",
                genre: "Khaleeji Hip-Hop",
                artists: [
                    "Freek",
                    "Flipperachi",
                    "Blvxb",
                    "Klash",
                    "DJMubarak",
                    "Daffy",
                    "Asayel",
                    "Nadine El Roubi",
                    "Dafencii",
                    "Queen G"
                ],
                backgroundCover: "1"
            ),
            GenreDefinition(
                cardTitle: "Mahraganat Gamda",
                genre: "Egyptian Mahraganat",
                artists: [
                    "Essam Saasa",
                    "Eslam Kabonga",
                    "Hamo Bika",
                    "Ziad Zaza",
                    "Team Elabda3",
                    "Houda Bondok",
                    "Magdy Elzahar",
                    "Hamo Eltekha",
                    "3enba",
                    "Ahmed Moza"
                ],
                backgroundCover: "2"
            ),
            GenreDefinition(
                cardTitle: "Dima Maghreb",
                genre: "Moroccan Pop",
                artists: [
                    "Saad Lamjarred",
                    "Douzi",
                    "Hatim Ammor",
                    "Asma Lmnawar",
                    "Manal Benchlikha",
                    "Ahmed Chawki",
                    "Dounia Batma",
                    "Lartiste",
                    "Zouhair Bahaoui",
                    "Aminux"
                ],
                backgroundCover: "3"
            )
        ]
        fallback = GenreDefinition(
            cardTitle: "World's Hits Collector",
            genre: "International Pop",
            artists: [
                "Billie Eilish",
                "Coldplay",
                "Lady Gaga",
                "Ariana Grande",
                "Ed Sheeran",
                "Lana Del Rey",
                "Adele",
                "Imagine Dragons",
                "Selena Gomez",
                "Bruno Mars"
            ],
            backgroundCover: "7"
        )
    }
}

