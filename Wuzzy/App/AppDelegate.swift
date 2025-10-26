import Cocoa

final class WuzzyAppDelegate: NSObject, NSApplicationDelegate {
    private let accessibilityAuthorizer = AccessibilityAuthorizer()
    private let hotkeyManager = HotkeyManager()
    private let windowIndexer = WindowIndexer()
    private let windowActivator = WindowActivator()
    private let searchEngine = FuzzyMatcher()
    private let screenRecordingAuthorizer = ScreenRecordingAuthorizer()
    private lazy var overlayViewModel = OverlayViewModel(searchEngine: searchEngine,
                                                         windowIndexer: windowIndexer,
                                                         windowActivator: windowActivator,
                                                         screenRecordingAuthorizer: screenRecordingAuthorizer)
    private lazy var overlayController = OverlayWindowController(viewModel: overlayViewModel,
                                                                 settings: settingsViewModel)

    let settingsViewModel: SettingsViewModel

    override init() {
        let defaults = UserDefaults.standard
        let storedHotkey = HotkeyStorage.load(from: defaults) ?? Hotkey.defaultShortcut
        settingsViewModel = SettingsViewModel(initialHotkey: storedHotkey,
                                              screenRecordingAuthorizer: screenRecordingAuthorizer)
        super.init()
        settingsViewModel.delegate = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        accessibilityAuthorizer.ensureAccessibilityPrivilege()
        overlayViewModel.accessibilityGranted = accessibilityAuthorizer.isTrusted
        screenRecordingAuthorizer.ensurePermissionPrompted()
        overlayViewModel.screenRecordingGranted = screenRecordingAuthorizer.isAuthorized
        settingsViewModel.refreshAccessibilityState()
        settingsViewModel.updateScreenRecordingStatus(isGranted: screenRecordingAuthorizer.isAuthorized)

        windowIndexer.start()
        hotkeyManager.register(hotkey: settingsViewModel.hotkey) { [weak self] in
            self?.overlayController.toggleOverlay()
        }

        overlayViewModel.onDismissRequested = { [weak self] in
            self?.overlayController.hideOverlay()
        }

        overlayViewModel.onWindowFocusRequired = { [weak self] in
            self?.overlayController.focusSearchField()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowIndexer.stop()
        hotkeyManager.unregister()
    }
}

extension WuzzyAppDelegate: SettingsViewModelDelegate {
    func settingsViewModel(_ viewModel: SettingsViewModel, didUpdateHotkey hotkey: Hotkey) {
        HotkeyStorage.store(hotkey: hotkey, defaults: UserDefaults.standard)
        hotkeyManager.register(hotkey: hotkey) { [weak self] in
            self?.overlayController.toggleOverlay()
        }
    }
}
