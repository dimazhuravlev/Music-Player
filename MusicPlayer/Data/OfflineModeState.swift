import SwiftUI

/// Глобальный переключатель офлайн-режима (Downloads → тоггл). Контент витрины переключается на `OfflineShowcase`.
final class OfflineModeState: ObservableObject {
    @Published var isEnabled = false
    /// 0…1: предпросмотр офлайн-позиции мини и таббара при оттягивании экрана Downloads (до отпускания).
    @Published var downloadsPullChromeProgress: CGFloat = 0
    /// Коллекция: 0 Favorites, 1 Downloads — чтобы pull-блобы и подсказка были только на Downloads (и в legacy-таббаре).
    @Published var collectionTopTabIndex: Int = 0
    /// После pull-to-offline: нижний хром не ниже этого значения, пока `offlineFlashCover` догоняет (вспышка снизу вверх с 0).
    @Published var offlineTransitionChromeFloor: CGFloat?
    /// Верхнее пятно на витрине Offline; нарастает синхронно с затуханием полноэкранной вспышки.
    @Published var headerGlowOpacity: Double = 0
    /// После выхода из офлайна: открыть таб Коллекции (0 Favorites, 1 Downloads).
    @Published var preferredCollectionTopTab: Int? = nil
    /// Шторка «Internet seems…» поверх всего UI (таббар, мини-плеер, локальный навбар).
    @Published var isSkeletonOfflineSheetPresented = false
}
