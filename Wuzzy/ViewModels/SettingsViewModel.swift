import ApplicationServices
import Combine
import Foundation

protocol SettingsViewModelDelegate: AnyObject {
    func settingsViewModel(_ viewModel: SettingsViewModel, didUpdateHotkey hotkey: Hotkey)
}

final class SettingsViewModel: ObservableObject {
    @Published var hotkey: Hotkey
    @Published private(set) var accessibilityGranted: Bool = AXIsProcessTrusted()
    @Published private(set) var screenRecordingGranted: Bool

    weak var delegate: SettingsViewModelDelegate?

    private let screenRecordingAuthorizer: ScreenRecordingAuthorizer

    init(initialHotkey: Hotkey, screenRecordingAuthorizer: ScreenRecordingAuthorizer) {
        self.hotkey = initialHotkey
        self.screenRecordingAuthorizer = screenRecordingAuthorizer
        self.screenRecordingGranted = screenRecordingAuthorizer.isAuthorized
        bind()
    }

    func refreshAccessibilityState() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    func refreshScreenRecordingState() {
        screenRecordingGranted = screenRecordingAuthorizer.isAuthorized
    }

    func requestScreenRecordingPermission() {
        screenRecordingAuthorizer.ensurePermissionPrompted()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshScreenRecordingState()
        }
    }

    func updateScreenRecordingStatus(isGranted: Bool) {
        screenRecordingGranted = isGranted
    }

    private func bind() {
        $hotkey
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                self.delegate?.settingsViewModel(self, didUpdateHotkey: newValue)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}
