import Foundation

/// Курация по **`genre_id` Deezer** (метаданные релиза), без поиска по названиям.
/// В публичном API нет отдельных id для post-hardcore, shoegaze и т.д. — только верхний уровень;
/// ниже — все жанры из `GET /genre`, которые по смыслу ближе всего к вашему списку.
enum DeezerMusicScope {
    /// Id жанров Deezer (Accept-Language: en), объединённые в один «зону интересов»:
    /// rock / alternative / metal, electronic pop & dark shades, jazz & fusion, hip hop.
    ///
    /// Смысловые привязки (один id покрывает много подстилей в каталоге):
    /// - **85** Alternative — indie, alternative rock, post-punk, art rock, shoegaze, dream pop, gothic rock
    /// - **152** Rock — rock, punk, psych / prog / experimental / noise rock (часто помечают как Rock)
    /// - **464** Metal — hardcore punk, metal
    /// - **129** Jazz — jazz
    /// - **169** Soul & Funk — fusion, jazz-funk, groove (fusion в Deezer часто здесь)
    /// - **153** Blues — blues, blues-rock; смежно с rock / jazz
    /// - **116** Rap/Hip Hop — hip hop
    /// - **132** Pop — dream pop, synth-pop, поп-ориентированные релизы
    /// - **106** Electro — electro, darkwave, synth, electronic
    /// - **113** Dance — electronic / dance-pop; часть synth-pop и клубной электроники в каталоге с таким тегом
    static let scopedGenreIds: [Int] = [
        85,
        152,
        464,
        129,
        169,
        153,
        116,
        132,
        106,
        113,
    ]

    static let allowedAlbumGenreIds: Set<Int> = Set(scopedGenreIds)

    /// Плейлисты с **глобальной / US** выдачей (исполнители для пула артистов).
    /// `GET /genre/{id}/artists` и локальные чарты при анонимном API завязаны на **IP** (в Сербии — сербские артисты);
    /// эти плейлисты по id дают международный чарт-контент независимо от региона.
    static let internationalSeedPlaylistIds: [Int] = [
        10_064_140_302, // TOP 50 GLOBAL 2026 🌎
        4_461_060_364, // Global Top 50 | 2025 Hits
        1_313_621_735, // Top USA
    ]

    /// Карусель «Downloaded Playlists» на вкладке Downloads: отдельные от альбомов обложки и названия (`GET /playlist/:id`).
    static let downloadsShowcasePlaylistIds: [Int] = [
        10_064_140_302,
        4_461_060_364,
        1_313_621_735,
        3_155_776_842, // Top Worldwide
        908_622_995, // En mode 60
        1_111_143_121, // Top Germany
        2_098_157_264, // Global Hits
        1_306_931_615, // Rock Essentials
    ]

    /// Сколько страниц треков плейлиста подряд (по `limit` треков на страницу).
    static let playlistTrackPages = 3

    static let playlistTracksPageLimit = 50
}
