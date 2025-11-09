import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section(header: Text("Shortcut")) {
                HotkeyRecorderView(hotkey: $viewModel.hotkey)
            }

            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $viewModel.theme) {
                    ForEach(OverlayTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Show window on", selection: $viewModel.windowDisplayPreference) {
                    ForEach(viewModel.displayOptions) { option in
                        Text(option.name).tag(option.preference)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Show windows from all workspaces", isOn: $viewModel.showAllWorkspaces)
            }

            Section(header: Text("Permissions")) {
                HStack {
                    Label(viewModel.accessibilityGranted ? "Accessibility enabled" : "Accessibility required",
                          systemImage: viewModel.accessibilityGranted ? "checkmark.shield" : "shield.slash")
                    Spacer()
                    Button("Check Again") {
                        viewModel.refreshAccessibilityState()
                    }
                }

                Button("Open System Settings") {
                    openAccessibilitySettings()
                }
                .disabled(viewModel.accessibilityGranted)

                Divider()

                HStack {
                    Label(viewModel.screenRecordingGranted ? "Screen Recording enabled" : "Screen Recording required",
                          systemImage: viewModel.screenRecordingGranted ? "checkmark.display" : "display.trianglebadge.exclamationmark")
                    Spacer()
                    Button("Request Access") {
                        viewModel.requestScreenRecordingPermission()
                    }
                }

                Button("Open Screen Recording Settings") {
                    openScreenRecordingSettings()
                }
                .disabled(viewModel.screenRecordingGranted)
            }

            Section(footer: Text("Wuzzy runs as a background utility. Use the shortcut to toggle the window and press Esc to hide it.")) {
                EmptyView()
            }
        }
        .padding(16)
        .frame(minWidth: 340)
        .onAppear {
            viewModel.updateDisplayOptions()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
