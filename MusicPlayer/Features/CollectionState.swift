import Foundation
import SwiftUI

/// Keeps the two most recent liked covers for the Collection tab.
final class CollectionState: ObservableObject {
    /// Older liked cover (shown on the left).
    @Published private(set) var previousCover: String?
    /// Most recent liked cover (shown on the right).
    @Published private(set) var latestCover: String?
    
    /// Records a newly liked cover and shifts the older one to the left slot.
    func registerLike(coverName: String) {
        guard !coverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        previousCover = latestCover
        latestCover = coverName
    }
    
    /// Convenience flag for rendering empty states.
    var hasCovers: Bool {
        previousCover != nil || latestCover != nil
    }
}

