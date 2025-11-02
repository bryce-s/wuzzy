# Wuzzy

Wuzzy is a SwiftUI-powered macOS window switcher that delivers instant fuzzy search across your current workspace. Summon the overlay with `⌥G`, type to filter, and press `Return` to focus the selected window. Press `Esc` (or click outside the panel) to dismiss it.

## Requirements
- macOS Ventura (13.0) or newer
- Xcode 15 or newer (for building)
- Accessibility permission granted to Wuzzy (required to focus other apps)

## Building & Running
1. Open `Wuzzy.xcodeproj` in Xcode.
2. Select the **Wuzzy** scheme.
3. Build & run (`⌘R`). The app will prompt macOS for accessibility access the first time it tries to focus another window.

To run via CLI, use:
```bash
xcodebuild -project Wuzzy.xcodeproj \
           -scheme Wuzzy \
           -configuration Debug \
           build
```
The resulting app bundle will be available under `build/Debug/Wuzzy.app`.

## Testing
Execute the unit tests from Xcode (`⌘U`) or via CLI:
```bash
xcodebuild -project Wuzzy.xcodeproj \
           -scheme Wuzzy \
           -configuration Debug \
           test
```

## Keyboard Shortcut
- Default shortcut: `⌥G`
- Change the shortcut in **Wuzzy ▸ Settings…**. Click **Change…**, press your desired combination, and it will be registered instantly.

## Accessibility Access
Wuzzy uses the Accessibility APIs to raise windows from other applications. If macOS reports that access is not granted, open System Settings ▸ Privacy & Security ▸ Accessibility and allow Wuzzy.

## Limitations
- Google Chrome (and some Chromium-based apps) refuse the `AXRaise`/`AXShow` accessibility actions with `kAXErrorCannotComplete`. Because Wuzzy relies on those calls to focus a specific window, Chrome windows cannot currently be raised individually—only the application comes to the front.
