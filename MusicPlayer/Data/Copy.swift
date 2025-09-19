import Foundation

struct ToastCopy {
    static let likeTitles: [String] = [
        "Cool! Tuning My Vibe with this pick",
        "Nice one! We’re tuning your recs",
        "Love your taste — keep feeding us",
        "Added to your Favorites",
        "You like it — we saved it",
        "Nice taste! Added to Collection",
        "Into the heart it goes",
        "Ya salam! That’s a vibe",
        "Niiice!",
        "Yalla, that’s a song"
    ]
    
    static func randomLikeTitle() -> String {
        likeTitles.randomElement() ?? "Added to Collection"
    }
}


