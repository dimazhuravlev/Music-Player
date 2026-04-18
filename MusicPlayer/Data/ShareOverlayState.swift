import SwiftUI

/// Глобальный шеринг-оверлей. Отложенное снятие с экрана хранится здесь, чтобы при новом `present()`
/// отменять таймеры прошлого закрытия — иначе после 2-го раза остаётся невидимый слой, перехватывающий тачи.
final class ShareOverlayState: ObservableObject {
    @Published private(set) var presentedShareEntity: ShareableEntity?
    /// Меняется при каждом `present()` — чтобы SwiftUI не переиспользовал старое состояние вью.
    @Published private(set) var presentationID = UUID()

    private var pendingRemovalWork: DispatchWorkItem?

    func present(_ entity: ShareableEntity) {
        pendingRemovalWork?.cancel()
        pendingRemovalWork = nil
        presentationID = UUID()
        presentedShareEntity = entity
    }

    func dismissImmediately() {
        pendingRemovalWork?.cancel()
        pendingRemovalWork = nil
        presentedShareEntity = nil
    }

    /// После анимации закрытия. Отменяется при следующем `present()` / `dismissImmediately()`.
    func scheduleRemovalAfterAnimation(_ delay: TimeInterval) {
        pendingRemovalWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingRemovalWork = nil
            self.presentedShareEntity = nil
        }
        pendingRemovalWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
