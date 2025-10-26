import SwiftUI

@main
struct WuzzyApp: App {
    @NSApplicationDelegateAdaptor(WuzzyAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(viewModel: appDelegate.settingsViewModel)
                .frame(width: 380, height: 240)
        }
    }
}
