import AppKit
import SwiftUI

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel
    @ObservedObject var focusController: OverlayFocusController
    var dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            header
            resultsList
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.red.opacity(0.6), lineWidth: 1)
                )
        )
        .padding()
        .onExitCommand {
            viewModel.requestDismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            dismissAction()
        }
        .frame(width: 560, height: 420)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            OverlaySearchField(text: $viewModel.query,
                               focusTick: focusController.focusTick,
                               placeholder: "Search windows…",
                               onSubmit: { viewModel.activateSelection() },
                               onCancel: { viewModel.requestDismiss() },
                               onMoveUp: { viewModel.moveSelection(delta: -1) },
                               onMoveDown: { viewModel.moveSelection(delta: 1) })
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .foregroundColor(.white)

            if !viewModel.accessibilityGranted {
                accessibilityPrompt
            } else if !viewModel.screenRecordingGranted {
                screenRecordingPrompt
            } else {
                Text("Enter focuses the selection • Esc closes Wuzzy")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var accessibilityPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Grant Accessibility access in System Settings › Privacy to enable focusing windows.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    private var screenRecordingPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Grant Screen Recording access to show window titles. (System Settings › Privacy › Screen Recording)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(viewModel.results) { result in
                    OverlayRow(result: result,
                               isSelected: result.window.id == viewModel.selectedWindowID)
                        .onTapGesture {
                            viewModel.selectedWindowID = result.window.id
                        }
                        .onTapGesture(count: 2) {
                            viewModel.selectedWindowID = result.window.id
                            viewModel.activateSelection()
                        }
                }
            }.padding(.top, 4)
        }
        .background(Color.black.opacity(0.01))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onMoveCommand { direction in
            switch direction {
            case .down:
                viewModel.moveSelection(delta: 1)
            case .up:
                viewModel.moveSelection(delta: -1)
            default:
                break
            }
        }
    }
}

private struct OverlayRow: View {
    let result: FuzzyMatchResult
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MatchedTextView(text: result.window.displayName,
                            matchedIndices: result.matchedIndices)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.red.opacity(0.35) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.red.opacity(0.7) : Color.white.opacity(0.08),
                                lineWidth: isSelected ? 1.5 : 1)
                )
        )
        .foregroundColor(.white)
        .font(.system(size: 16, weight: .medium, design: .monospaced))
    }
}
