import Foundation

// MARK: - Album Data Models
struct AlbumData {
    let albumImageName: String
    let artistImageName: String
    let artistName: String
    let releaseYear: Int
    let artistBio: String
}

// MARK: - Album Data Manager
class AlbumDataManager {
    static let shared = AlbumDataManager()
    
    // Cache for loaded album data to improve performance
    private var cachedData: [String: AlbumData] = [:]
    private let queue = DispatchQueue(label: "album.data.queue", qos: .userInitiated)
    
    private init() {}
    
    func getAlbumData(for albumName: String?) -> AlbumData {
        guard let albumName = albumName else {
            return AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Artist",
                releaseYear: 2024,
                artistBio: "Artist biography not available."
            )
        }
        
        // Check cache first
        if let cachedAlbum = cachedData[albumName] {
            return cachedAlbum
        }
        
        let data: [String: AlbumData] = [
            "Beautiful Things": AlbumData(
                albumImageName: "benson boone",
                artistImageName: "benson boone",
                artistName: "Benson Boone",
                releaseYear: 2024,
                artistBio: "This album rips through the noise to awaken your senses and spark a fire in your restless soul. Beautiful Things captures the essence of modern pop with heartfelt lyrics and soaring melodies that will stay with you long after the music stops. Benson Boone's journey from American Idol contestant to chart-topping artist represents the modern dream of musical success, blending raw talent with contemporary production techniques. His ability to craft emotionally resonant songs that speak to both personal struggles and universal experiences has made him one of the most compelling voices in today's pop landscape. The album showcases his growth as both a songwriter and performer, with each track carefully crafted to tell a story that listeners can connect with on a deeply personal level. Boone's distinctive vocal style, characterized by its emotional depth and technical precision, brings authenticity to every lyric he sings. The production on Beautiful Things seamlessly blends organic instrumentation with modern electronic elements, creating a sound that feels both timeless and cutting-edge. This collection of songs represents not just an album, but a musical journey that invites listeners to explore the complexities of human emotion through the lens of contemporary pop music."
            ),
            "Love Letters / رسائل حب": AlbumData(
                albumImageName: "saint levant",
                artistImageName: "saint levant",
                artistName: "Saint Levant",
                releaseYear: 2023,
                artistBio: "A beautiful fusion of Arabic and English lyrics that tells stories of love, loss, and hope. Saint Levant brings together cultural influences to create something truly unique and moving. This groundbreaking artist represents the new generation of Middle Eastern musicians who are breaking down cultural barriers and creating music that speaks to a global audience. Saint Levant's innovative approach to blending traditional Arabic musical elements with contemporary Western production techniques has created a sound that is both familiar and refreshingly new. His lyrics, which seamlessly flow between Arabic and English, tell deeply personal stories that resonate with listeners from diverse cultural backgrounds. The artist's commitment to authenticity and cultural representation has made him a powerful voice for the Middle Eastern diaspora, while his universal themes of love, heartbreak, and hope connect with audiences worldwide."
            ),
            "Song 2": AlbumData(
                albumImageName: "blur",
                artistImageName: "userpic",
                artistName: "Blur",
                releaseYear: 1997,
                artistBio: "Blur's iconic track that defined the Britpop era. With its raw energy and unforgettable 'woo-hoo' chorus, this song remains one of the most recognizable tracks in alternative rock history. This explosive anthem captured the spirit of 90s Britain, perfectly encapsulating the cultural moment when British music was reclaiming its place on the global stage. Damon Albarn's distinctive vocal delivery, combined with Graham Coxon's aggressive guitar work, created a sound that was both chaotic and controlled, reflecting the contradictions of modern life. The song's simple yet powerful structure, built around a driving rhythm and memorable hook, made it an instant classic that continues to resonate with new generations of listeners. Blur's ability to blend punk energy with pop accessibility helped define the Britpop movement, influencing countless bands that followed. The track's cultural impact extended far beyond music, becoming a symbol of British identity and youth culture during the 1990s. Its inclusion in films, television shows, and sporting events has cemented its place in popular culture, while its raw emotional power continues to move audiences decades after its release. Song 2 represents the perfect marriage of artistic ambition and commercial appeal, proving that great music can be both challenging and universally accessible."
            ),
            "Friday I'm in Love": AlbumData(
                albumImageName: "cure",
                artistImageName: "userpic",
                artistName: "The Cure",
                releaseYear: 1992,
                artistBio: "The Cure's most upbeat and optimistic song, celebrating the joy of love and the anticipation of the weekend. A perfect blend of pop sensibility and gothic rock aesthetics. This infectious track marked a significant departure from The Cure's typically melancholic sound, showcasing Robert Smith's versatility as both a songwriter and performer. The song's bright, jangly guitar work and Smith's surprisingly cheerful vocal delivery created a perfect contrast to the band's darker material, proving that even the masters of gothic rock could create pure pop magic. The track's simple yet effective structure, built around a memorable melody and Smith's distinctive vocal style, made it an instant hit that crossed over to mainstream audiences. The song's celebration of love and the simple pleasures of life resonated with listeners who were drawn to its genuine emotional warmth and infectious energy. Smith's ability to craft lyrics that are both poetic and accessible helped establish the song as one of The Cure's most beloved tracks, while its production values showcased the band's evolution from underground heroes to mainstream success."
            ),
            "Equinox": AlbumData(
                albumImageName: "aquarium",
                artistImageName: "userpic",
                artistName: "Aquarium",
                releaseYear: 1998,
                artistBio: "Russian rock band Aquarium's masterpiece that explores themes of balance, change, and the eternal cycle of life. A poetic journey through sound and emotion. This seminal work represents the pinnacle of Russian alternative rock, showcasing Boris Grebenshchikov's extraordinary talent as both a lyricist and composer. The album's intricate arrangements and philosophical depth reflect the band's evolution from underground Soviet rock pioneers to internationally recognized artists. Grebenshchikov's distinctive vocal style, combined with the band's innovative use of traditional Russian instruments alongside modern rock elements, creates a sound that is uniquely their own. The album's themes of spiritual searching and existential questioning resonated deeply with Russian audiences during a time of great social and political change, making it a cultural touchstone for an entire generation. Aquarium's ability to blend Western rock influences with distinctly Russian sensibilities helped establish them as one of the most important bands in the history of Russian popular music. The album's production values, which seamlessly integrate acoustic and electronic elements, demonstrate the band's mastery of both traditional and modern musical techniques."
            ),
            "Bohemian Rhapsody": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Queen",
                releaseYear: 1975,
                artistBio: "Queen's magnum opus that defies categorization. This six-minute epic combines opera, rock, and ballad in a way that had never been done before, creating one of the most iconic songs in music history. Freddie Mercury's extraordinary vision and Brian May's innovative guitar work came together to create a masterpiece that revolutionized popular music and established new standards for artistic ambition in rock. The song's complex structure, which seamlessly blends multiple musical genres and emotional tones, represents one of the most ambitious compositions ever attempted in popular music."
            ),
            "Hotel California": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Eagles",
                releaseYear: 1976,
                artistBio: "The Eagles' haunting tale of excess and disillusionment in California. With its intricate guitar work and mysterious lyrics, this song has become one of the most analyzed and beloved tracks in rock history. This epic composition represents the pinnacle of 1970s rock craftsmanship, showcasing the band's exceptional musicianship and Don Henley's masterful storytelling abilities. The song's complex narrative structure, which weaves together themes of hedonism, spiritual emptiness, and the dark side of the American dream, creates a compelling allegory that resonates with listeners across generations. The track's distinctive guitar work, featuring the legendary dueling solos by Don Felder and Joe Walsh, represents some of the most memorable instrumental passages in rock history. Henley's distinctive vocal delivery, combined with the band's signature harmonies, creates an atmosphere that is both seductive and foreboding, perfectly capturing the song's themes of temptation and moral decay. The song's production values, which seamlessly blend acoustic and electric elements, demonstrate the band's mastery of studio techniques and their ability to create rich, layered soundscapes. The track's cultural impact extends far beyond music, becoming a symbol of the excesses and contradictions of American culture during the 1970s. Its enduring popularity and continued relevance demonstrate how great art can capture universal truths about human nature and society, making it one of the most important songs in the history of popular music."
            ),
            "Stairway to Heaven": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Led Zeppelin",
                releaseYear: 1971,
                artistBio: "Led Zeppelin's epic masterpiece that builds from acoustic ballad to thunderous rock anthem. Often considered one of the greatest rock songs ever recorded, it showcases the band's musical versatility and storytelling prowess. This eight-minute journey through musical landscapes represents the pinnacle of progressive rock, demonstrating Robert Plant's extraordinary vocal range and Jimmy Page's innovative guitar techniques. The song's complex structure, which seamlessly transitions from gentle acoustic passages to explosive rock sections, creates a dynamic listening experience that has captivated audiences for decades. Plant's mystical lyrics, which draw from Celtic mythology and spiritual themes, add layers of meaning that continue to inspire interpretation and analysis. The track's innovative production techniques, including the use of multiple guitar tracks and complex studio effects, set new standards for rock music production and influenced countless artists who followed. The song's cultural impact extends far beyond music, becoming a symbol of artistic ambition and creative freedom that continues to inspire musicians across all genres. Its enduring popularity, demonstrated by its continued presence in popular culture and its ability to connect with new generations of listeners, proves that great art transcends time and cultural boundaries. The track's influence on rock music cannot be overstated, as it helped establish the template for epic rock compositions and demonstrated the potential for popular music to be both commercially successful and artistically ambitious."
            ),
            "Imagine": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "John Lennon",
                releaseYear: 1971,
                artistBio: "John Lennon's timeless anthem for peace and unity. This simple yet powerful song continues to inspire generations with its message of hope and the vision of a world without conflict or division. This iconic composition represents Lennon's most profound artistic statement, combining his personal philosophy with universal themes that resonate across cultures and generations. The song's minimalist arrangement, featuring Lennon's gentle piano playing and understated vocal delivery, creates an intimate atmosphere that draws listeners into its message of hope and possibility. The track's simple yet profound lyrics, which envision a world without borders, religions, or possessions, challenge listeners to imagine a better future while acknowledging the difficulties of achieving such a vision. Lennon's ability to craft a song that is both deeply personal and universally accessible demonstrates his mastery of the art of songwriting and his understanding of music's power to inspire social change."
            ),
            "Billie Jean": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Michael Jackson",
                releaseYear: 1982,
                artistBio: "Michael Jackson's groundbreaking hit that revolutionized pop music. With its infectious bassline and Jackson's signature vocal style, this song became a cultural phenomenon and remains one of the most influential tracks in music history. This revolutionary composition represents the pinnacle of Jackson's artistic vision, combining innovative production techniques with his extraordinary vocal abilities to create a sound that was both futuristic and deeply rooted in soul and funk traditions."
            ),
            "Sweet Child O' Mine": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Guns N' Roses",
                releaseYear: 1987,
                artistBio: "Guns N' Roses' power ballad that combines Slash's iconic guitar riff with Axl Rose's emotional vocals. This song became the band's signature track and a defining moment of 80s rock music. This epic composition represents the pinnacle of 1980s hard rock, showcasing the band's exceptional musicianship and their ability to blend raw energy with melodic sophistication."
            ),
            "Smells Like Teen Spirit": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Nirvana",
                releaseYear: 1991,
                artistBio: "Nirvana's anthem that defined the grunge movement and changed the course of rock music. With its raw energy and Kurt Cobain's distinctive vocals, this song became the voice of a generation and remains a cultural touchstone. This revolutionary composition represents the defining moment of the grunge movement, capturing the angst and disillusionment of Generation X while establishing new standards for alternative rock. Kurt Cobain's distinctive vocal style, which combines raw emotion with technical precision, created a sound that was both aggressive and vulnerable, perfectly capturing the contradictions of youth culture in the early 1990s."
            ),
            "Wonderwall": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Oasis",
                releaseYear: 1995,
                artistBio: "Oasis's acoustic masterpiece that became one of the most recognizable songs of the 90s. With Noel Gallagher's melodic guitar work and Liam's distinctive vocals, this song captured the essence of Britpop and remains a timeless classic. This iconic composition represents the pinnacle of the Britpop movement, showcasing Noel Gallagher's exceptional songwriting abilities and Liam Gallagher's distinctive vocal style. The song's simple yet effective structure, built around a memorable melody and Gallagher's distinctive vocal delivery, made it an instant hit that crossed over to mainstream audiences around the world. The track's themes of love, hope, and personal struggle, combined with its accessible musical style, helped establish Oasis as one of the most important bands of the 1990s. The song's cultural impact extends far beyond music, becoming a symbol of British identity and youth culture during the decade, while its universal themes continue to resonate with listeners across different cultures and generations. The track's influence on popular culture, demonstrated by its continued presence in films, television shows, and public events, proves that great art can transcend its original context and become a permanent part of the cultural landscape. The song's enduring popularity and continued relevance demonstrate how great music can capture universal truths about human experience and provide comfort and inspiration to listeners during difficult times."
            ),
            "Creep": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Radiohead",
                releaseYear: 1992,
                artistBio: "Radiohead's breakthrough hit that showcased Thom Yorke's emotional vulnerability and the band's unique sound. This song's raw honesty and powerful dynamics made it an instant classic and launched Radiohead's legendary career. This groundbreaking composition represents the defining moment of Radiohead's early career, capturing the band's distinctive sound and Thom Yorke's extraordinary vocal abilities. The song's simple yet effective structure, built around a memorable melody and Yorke's distinctive vocal style, made it an instant hit that crossed over to mainstream audiences around the world. The track's themes of alienation, self-doubt, and emotional vulnerability, combined with its accessible musical style, helped establish Radiohead as one of the most important bands of the 1990s. The song's cultural impact extends far beyond music, becoming a symbol of alternative rock culture and the era of grunge, while its universal themes continue to resonate with listeners across different cultures and generations."
            ),
            "Losing My Religion": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "R.E.M.",
                releaseYear: 1991,
                artistBio: "R.E.M.'s introspective masterpiece that explores themes of doubt and spiritual crisis. With Michael Stipe's poetic lyrics and the band's distinctive jangle-pop sound, this song became one of the most influential tracks of the alternative rock era. This iconic composition represents the pinnacle of R.E.M.'s artistic vision, showcasing Michael Stipe's exceptional songwriting abilities and the band's distinctive musical style. The song's complex structure, which seamlessly blends acoustic and electric elements, creates a rich, layered soundscape that has captivated audiences for decades. Stipe's distinctive vocal style, combined with the band's innovative use of mandolin and other traditional instruments, creates a sound that is both familiar and refreshingly new. The track's themes of spiritual searching and existential questioning, combined with its accessible musical style, helped establish R.E.M. as one of the most important bands of the alternative rock movement. The song's cultural impact extends far beyond music, becoming a symbol of the 1990s alternative culture and the era of introspection, while its universal themes continue to resonate with listeners across different cultures and generations. The track's influence on popular culture, demonstrated by its continued presence in films, television shows, and public events, proves that great art can transcend its original context and become a permanent part of the cultural landscape."
            ),
            "Black": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Pearl Jam",
                releaseYear: 1991,
                artistBio: "Pearl Jam's emotional ballad that showcases Eddie Vedder's powerful vocals and the band's ability to create deeply moving music. This song's raw emotion and beautiful melody made it one of the standout tracks of the grunge movement. This powerful composition represents the pinnacle of Pearl Jam's early career, showcasing Eddie Vedder's extraordinary vocal abilities and the band's exceptional musicianship. The song's simple yet effective structure, built around a memorable melody and Vedder's distinctive vocal style, made it an instant classic that continues to resonate with new generations of listeners."
            ),
            "Come As You Are": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Nirvana",
                releaseYear: 1991,
                artistBio: "Nirvana's haunting track that combines Kurt Cobain's introspective lyrics with the band's signature grunge sound. This song's melancholic beauty and powerful message made it one of the most memorable tracks of the 90s alternative rock scene."
            ),
            "Alive": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Pearl Jam",
                releaseYear: 1991,
                artistBio: "Pearl Jam's powerful anthem that showcases the band's raw energy and Eddie Vedder's distinctive vocals. This song's driving rhythm and emotional intensity made it one of the defining tracks of the grunge movement and Pearl Jam's breakthrough hit."
            ),
            "Jeremy": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Pearl Jam",
                releaseYear: 1991,
                artistBio: "Pearl Jam's socially conscious masterpiece that addresses themes of bullying and teenage alienation. With its powerful message and the band's signature sound, this song became one of the most important and influential tracks of the 90s alternative rock era."
            ),
            "Even Flow": AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: "Pearl Jam",
                releaseYear: 1991,
                artistBio: "Pearl Jam's energetic track that showcases the band's musical prowess and Eddie Vedder's dynamic vocal range. This song's driving rhythm and powerful guitar work made it one of the standout tracks of their debut album and a fan favorite."
            )
        ]
        
        let result = data[albumName] ?? AlbumData(
            albumImageName: "album",
            artistImageName: "userpic",
            artistName: "Artist",
            releaseYear: 2024,
            artistBio: "Artist biography not available."
        )
        
        // Cache the result for future use
        cachedData[albumName] = result
        return result
    }
}
