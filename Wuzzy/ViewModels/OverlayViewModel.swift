import AppKit
import ApplicationServices
import Combine
import Foundation

final class OverlayViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [FuzzyMatchResult] = []
    @Published var selectedWindowID: CGWindowID?
    @Published var accessibilityGranted: Bool = AXIsProcessTrusted()
    @Published var screenRecordingGranted: Bool = true

    var onDismissRequested: (() -> Void)?
    var onWindowFocusRequired: (() -> Void)?

    private let searchEngine: FuzzyMatcher
    private let windowIndexer: WindowIndexer
    private let windowActivator: WindowActivator
    private let screenRecordingAuthorizer: ScreenRecordingAuthorizer
    private var cancellables = Set<AnyCancellable>()
    private let searchQueue = DispatchQueue(label: "com.brycesmith.wuzzy.search", qos: .userInitiated)
    private var currentWindows: [WindowInfo] = []

    init(searchEngine: FuzzyMatcher,
         windowIndexer: WindowIndexer,
         windowActivator: WindowActivator,
         screenRecordingAuthorizer: ScreenRecordingAuthorizer) {
        self.searchEngine = searchEngine
        self.windowIndexer = windowIndexer
        self.windowActivator = windowActivator
        self.screenRecordingAuthorizer = screenRecordingAuthorizer
        self.screenRecordingGranted = screenRecordingAuthorizer.isAuthorized
        bind()
    }

    func showOverlay() {
        selectedWindowID = results.first?.window.id
        onWindowFocusRequired?()
    }

    func requestDismiss() {
        onDismissRequested?()
    }

    func overlayDidHide() {
        query = ""
    }

    func moveSelection(delta: Int) {
        guard !results.isEmpty else { return }
        guard let current = selectedWindowID,
              let index = results.firstIndex(where: { $0.window.id == current }) else {
            selectedWindowID = results.first?.window.id
            return
        }
        let newIndex = (index + delta + results.count) % results.count
        selectedWindowID = results[newIndex].window.id
    }

    func activateSelection() {
        guard let selectedID = selectedWindowID,
              let target = results.first(where: { $0.window.id == selectedID }) else {
            return
        }
        windowActivator.activate(window: target.window)
        requestDismiss()
    }

    private func bind() {
        windowIndexer.onChange = { [weak self] windows in
            self?.currentWindows = windows
            self?.performSearch()
        }

        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .map { [weak self] _ in self?.screenRecordingAuthorizer.isAuthorized ?? true }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                self?.screenRecordingGranted = granted
            }
            .store(in: &cancellables)
    }

    private func performSearch() {
        let windows = currentWindows
        let query = self.query

        searchQueue.async { [weak self] in
            guard let self else { return }
            let matches = self.searchEngine.matches(for: query, in: windows)
            DispatchQueue.main.async {
                let previousSelection = self.selectedWindowID
                self.results = matches
                if let previousSelection,
                   matches.contains(where: { $0.window.id == previousSelection }) {
                    self.selectedWindowID = previousSelection
                } else {
                    self.selectedWindowID = matches.first?.window.id
                }
            }
        }
    }
}
