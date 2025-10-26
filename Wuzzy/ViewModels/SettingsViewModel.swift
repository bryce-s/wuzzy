import AppKit
import ApplicationServices
import Combine
import Foundation

protocol SettingsViewModelDelegate: AnyObject {
    func settingsViewModel(_ viewModel: SettingsViewModel, didUpdateHotkey hotkey: Hotkey)
}

final class SettingsViewModel: ObservableObject {
    struct DisplayOption: Identifiable, Hashable {
        let preference: OverlayDisplayPreference
        let name: String

        var id: String {
            preference.identifier
        }
    }

    @Published var hotkey: Hotkey
    @Published private(set) var accessibilityGranted: Bool = AXIsProcessTrusted()
    @Published private(set) var screenRecordingGranted: Bool
    @Published var windowDisplayPreference: OverlayDisplayPreference
    @Published private(set) var displayOptions: [DisplayOption] = []

    weak var delegate: SettingsViewModelDelegate?

    private let screenRecordingAuthorizer: ScreenRecordingAuthorizer
    private var cancellables = Set<AnyCancellable>()

    init(initialHotkey: Hotkey,
         screenRecordingAuthorizer: ScreenRecordingAuthorizer) {
        self.hotkey = initialHotkey
        self.screenRecordingAuthorizer = screenRecordingAuthorizer
        self.screenRecordingGranted = screenRecordingAuthorizer.isAuthorized
        let defaults = UserDefaults.standard
        self.windowDisplayPreference = OverlayDisplayPreferenceStorage.load(from: defaults) ?? .active
        updateDisplayOptions()
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

        $windowDisplayPreference
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { newValue in
                OverlayDisplayPreferenceStorage.store(preference: newValue, defaults: UserDefaults.standard)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDisplayOptions()
            }
            .store(in: &cancellables)
    }

    func updateDisplayOptions() {
        let screens = NSScreen.screens

        var options: [DisplayOption] = [
            DisplayOption(preference: .primary, name: "Primary Display"),
            DisplayOption(preference: .active, name: "Active Display (under pointer)")
        ]

        var availableIdentifiers = Set<String>()
        var identifierToName: [String: String] = [:]

        for (index, screen) in screens.enumerated() {
            guard let identifier = screen.displayIdentifier else { continue }
            availableIdentifiers.insert(identifier)
            let screenName = makeDisplayName(for: screen, index: index)
            identifierToName[identifier] = screenName
            let preference = OverlayDisplayPreference.display(id: identifier, name: screenName)
            options.append(DisplayOption(preference: preference, name: screenName))
        }

        displayOptions = options

        switch windowDisplayPreference {
        case .primary, .active:
            break
        case let .display(id, _):
            if let updatedName = identifierToName[id] {
                if windowDisplayPreference.storedName != updatedName {
                    windowDisplayPreference = .display(id: id, name: updatedName)
                }
            } else if !availableIdentifiers.contains(id) {
                windowDisplayPreference = .primary
            }
        }
    }

    private func makeDisplayName(for screen: NSScreen, index: Int) -> String {
        let baseName: String
        if #available(macOS 10.15, *) {
            baseName = screen.localizedName
        } else {
            baseName = "Display"
        }

        return "\(baseName) (\(index + 1))"
    }
}
