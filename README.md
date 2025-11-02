# Wuzzy

Wuzzy is a SwiftUI-powered macOS window switcher that delivers instant fuzzy search across your current workspace. Summon the overlay with `⌥G`, type to filter, and press `Return` to focus the selected window. Press `Esc` (or click outside the panel) to dismiss it.

## Requirements
- macOS Ventura (13.0) or newer
- Xcode 15 or newer (for building)
- Accessibility permission granted to Wuzzy (required to focus other apps)

## Installing via Homebrew
1. Install Homebrew if it is not already available.
2. Add the tap: `brew tap bryce-s/wuzzy`
3. Install the cask: `brew install --cask wuzzy`
4. Launch Wuzzy from `/Applications` or with Spotlight.
5. To remove it later: `brew uninstall wuzzy && brew untap bryce-s/wuzzy`

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

## Publishing a Homebrew Release
Follow these steps whenever you cut a new version for the tap.

1. **Build the Release Artifact**
   ```bash
   xcodebuild -project Wuzzy.xcodeproj \
              -scheme Wuzzy \
              -configuration Release \
              -derivedDataPath BuildDerivedData \
              build

   ditto -c -k --sequesterRsrc --keepParent \
         BuildDerivedData/Build/Products/Release/Wuzzy.app \
         Wuzzy-<version>.zip
   ```
   Replace `<version>` with the semantic version you are releasing.
2. **Record the Checksum**  
   `shasum -a 256 Wuzzy-<version>.zip`
3. **Publish the Artifact**  
   Use the GitHub CLI (from either the Wuzzy repo or this tap) to attach the zip to a release in `github.com/bryce-s/wuzzy`:
   ```bash
   gh release create v<version> Wuzzy-<version>.zip \
     --repo bryce-s/wuzzy \
     --title "Wuzzy <version>" \
     --notes "Release notes go here."
   ```
   If the tag already exists, swap `create` for `upload` and add `--clobber` to replace the asset.
4. **Update the Tap**  
   Edit `Casks/wuzzy.rb` with the new `version`, `sha256`, and `url` (the URL should point at the uploaded zip on GitHub Releases).
5. **Commit and Push**  
   `git add Casks/wuzzy.rb && git commit -m "Update Wuzzy to <version>" && git push`
6. **Verify the Install**  
   On a clean machine (or after untapping), run:
   ```bash
   brew untap bryce-s/wuzzy || true
   brew tap bryce-s/wuzzy
   brew install --cask wuzzy
   ```
   Confirm that the install succeeds and Wuzzy launches.

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
