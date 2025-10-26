import AppKit
import Carbon
import SwiftUI

struct HotkeyRecorderView: View {
    @Binding var hotkey: Hotkey

    @State private var isRecording = false
    @State private var localMonitor: Any?
    @State private var globalMonitor: Any?
    @State private var temporaryDisplay: String?

    var body: some View {
        HStack {
            Text(currentDisplay)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.08))
                )
            Spacer()
            Button(isRecording ? "Cancel" : "Change…") {
                toggleRecording()
            }
            .onExitCommand {
                cancelRecording()
            }
        }
        .onDisappear {
            cancelRecording()
        }
    }

    private var currentDisplay: String {
        if let temporaryDisplay {
            return temporaryDisplay
        }

        return isRecording ? "Press new shortcut…" : hotkey.displayString
    }

    private func toggleRecording() {
        if isRecording {
            cancelRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        temporaryDisplay = nil

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event: event)
            return nil
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            handle(event: event)
        }
    }

    private func cancelRecording() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        self.localMonitor = nil
        self.globalMonitor = nil
        isRecording = false
        temporaryDisplay = nil
    }

    private func finalize(with newHotkey: Hotkey) {
        hotkey = newHotkey
        cancelRecording()
    }

    private func handle(event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            cancelRecording()
            return
        }

        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if modifiers.isEmpty {
            temporaryDisplay = "Add a modifier key"
            return
        }

        guard let newHotkey = Hotkey(event: event) else {
            temporaryDisplay = "Unsupported key"
            return
        }

        temporaryDisplay = newHotkey.displayString
        finalize(with: newHotkey)
    }
}
