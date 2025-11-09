import Cocoa
import Combine

final class WuzzyAppDelegate: NSObject, NSApplicationDelegate {
    private let accessibilityAuthorizer = AccessibilityAuthorizer()
    private let hotkeyManager = HotkeyManager()
    private let windowIndexer = WindowIndexer()
    private let windowActivator = WindowActivator()
    private let searchEngine = FuzzyMatcher()
    private let screenRecordingAuthorizer = ScreenRecordingAuthorizer()
    private let menuBarManager = MenuBarManager()
    private lazy var overlayViewModel = OverlayViewModel(searchEngine: searchEngine,
                                                         windowIndexer: windowIndexer,
                                                         windowActivator: windowActivator,
                                                         screenRecordingAuthorizer: screenRecordingAuthorizer)
    private lazy var overlayController = OverlayWindowController(viewModel: overlayViewModel,
                                                                 settings: settingsViewModel)
    private var cancellables = Set<AnyCancellable>()

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
        settingsViewModel.updateDisplayOptions()

        // Setup menu bar icon
        menuBarManager.setup()
        menuBarManager.settingsViewModel = settingsViewModel
        menuBarManager.onToggleOverlay = { [weak self] in
            self?.overlayController.toggleOverlay()
        }

        // Bind showAllWorkspaces setting to WindowIndexer
        windowIndexer.showAllWorkspaces = settingsViewModel.showAllWorkspaces
        settingsViewModel.$showAllWorkspaces
            .sink { [weak self] showAll in
                self?.windowIndexer.showAllWorkspaces = showAll
            }
            .store(in: &cancellables)

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
