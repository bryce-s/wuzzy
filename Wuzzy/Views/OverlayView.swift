import AppKit
import SwiftUI

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel
    @ObservedObject var focusController: OverlayFocusController
    @ObservedObject var settings: SettingsViewModel
    var dismissAction: () -> Void

    private var theme: OverlayThemeStyle { settings.theme.style }
    private var helpFont: Font {
        settings.theme == .macOS ? .system(size: 12, weight: .regular, design: .default)
                                 : .system(size: 12, weight: .regular, design: .monospaced)
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            resultsList
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            backgroundLayer
                .clipShape(cornerShape)
        )
        .overlay(
            borderOverlay
        )
        .compositingGroup()
        .shadow(color: theme.borderShadow?.color ?? .clear,
                radius: theme.borderShadow?.radius ?? 0,
                x: theme.borderShadow?.x ?? 0,
                y: theme.borderShadow?.y ?? 0)
        .padding(theme.borderShadow != nil ? max(40, (theme.borderShadow?.radius ?? 0) * 1.5) : 0)
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
            SearchFieldContainer(theme: theme) {
                OverlaySearchField(text: $viewModel.query,
                                   focusTick: focusController.focusTick,
                                   placeholder: "Search windows…",
                                   style: theme,
                                   onSubmit: { viewModel.activateSelection() },
                                   onCancel: { viewModel.requestDismiss() },
                                   onMoveUp: { viewModel.moveSelection(delta: -1) },
                                   onMoveDown: { viewModel.moveSelection(delta: 1) })
            }

            if !viewModel.accessibilityGranted {
                accessibilityPrompt
            } else if !viewModel.screenRecordingGranted {
                screenRecordingPrompt
            } else {
                Text("Enter focuses the selection • Esc closes Wuzzy")
                    .font(helpFont)
                    .foregroundColor(theme.secondaryText)
            }
        }
    }

    private var accessibilityPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Grant Accessibility access in System Settings › Privacy to enable focusing windows.")
                .font(helpFont)
                .foregroundColor(theme.secondaryText)
        }
    }

    private var screenRecordingPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Grant Screen Recording access to show window titles. (System Settings › Privacy › Screen Recording)")
                .font(helpFont)
                .foregroundColor(theme.secondaryText)
        }
    }

    private var resultsList: some View {
        ResultsListView(results: viewModel.results,
                        selectedWindowID: $viewModel.selectedWindowID,
                        theme: theme,
                        onMove: viewModel.moveSelection,
                        onActivate: viewModel.activateSelection)
    }
}

private struct OverlayRow: View {
    let result: FuzzyMatchResult
    let isSelected: Bool
    let theme: OverlayThemeStyle

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MatchedTextView(text: result.window.displayName,
                            matchedIndices: result.matchedIndices,
                            baseColor: (isSelected ? theme.highlightText.nsColor : theme.primaryTextNSColor),
                            highlightColor: theme.matchUnderlineColor)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? theme.highlightBackground : Color.clear)
                .overlay(alignment: .center) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.highlightBorder, lineWidth: 1.5)
                    } else if theme.borderWidth > 0 {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.border.opacity(0.2), lineWidth: theme.borderWidth)
                    }
                }
        )
        .font(theme.resultFont)
    }
}

private struct ResultsListView: View {
    let results: [FuzzyMatchResult]
    @Binding var selectedWindowID: CGWindowID?
    let theme: OverlayThemeStyle
    let onMove: (Int) -> Void
    let onActivate: () -> Void

    private var resultIDs: [CGWindowID] {
        results.map { $0.window.id }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(results) { result in
                        OverlayRow(result: result,
                                   isSelected: result.window.id == selectedWindowID,
                                   theme: theme)
                            .id(result.window.id)
                            .onTapGesture {
                                selectedWindowID = result.window.id
                                DispatchQueue.main.async {
                                    scrollToSelection(proxy: proxy, animated: true)
                                }
                            }
                            .onTapGesture(count: 2) {
                                selectedWindowID = result.window.id
                                onActivate()
                            }
                    }
                }
                .padding(.top, 4)
            }
            .background(theme.background.opacity(0.01))
            .overlay(alignment: .center) {
                if theme.borderWidth > 0 {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(theme.border.opacity(0.15), lineWidth: theme.borderWidth)
                }
            }
            .onChange(of: selectedWindowID) { _ in
                scrollToSelection(proxy: proxy, animated: false)
            }
            .onChange(of: resultIDs) { _ in
                scrollToSelection(proxy: proxy, animated: false)
            }
            .onMoveCommand { direction in
                switch direction {
                case .down:
                    onMove(1)
                case .up:
                    onMove(-1)
                default:
                    break
                }
                DispatchQueue.main.async {
                    scrollToSelection(proxy: proxy, animated: true)
                }
            }
            .onAppear {
                scrollToSelection(proxy: proxy, animated: false)
            }
        }
    }

    private func scrollToSelection(proxy: ScrollViewProxy, animated: Bool) {
        guard let selectedWindowID else { return }
        let action = {
            proxy.scrollTo(selectedWindowID, anchor: .center)
        }
        if animated {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.15)) {
                    action()
                }
            }
        } else {
            DispatchQueue.main.async {
                action()
            }
        }
    }
}

private extension OverlayView {
    var cornerShape: RoundedRectangle { RoundedRectangle(cornerRadius: 14, style: .continuous) }

    @ViewBuilder
    var backgroundLayer: some View {
        if settings.theme == .macOS {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
        } else {
            theme.background
        }
    }

    @ViewBuilder
    var borderOverlay: some View {
        if theme.borderWidth > 0 {
            cornerShape.stroke(theme.border, lineWidth: theme.borderWidth)
        } else {
            EmptyView()
        }
    }
}

private struct SearchFieldContainer<Content: View>: View {
    let theme: OverlayThemeStyle
    @ViewBuilder var content: () -> Content

    var body: some View {
        if theme.usesSpotlightSearchField {
            content()
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
        } else {
            content()
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.searchFieldBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.searchFieldBorder, lineWidth: 1)
                )
        }
    }
}
