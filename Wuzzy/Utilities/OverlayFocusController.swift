import Combine
import Foundation

final class OverlayFocusController: ObservableObject {
    @Published private(set) var focusTick: Int = 0

    func requestFocus() {
        focusTick += 1
    }
}
