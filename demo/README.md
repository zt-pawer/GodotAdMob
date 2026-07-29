# GodotAdMob Demo

Test project exercising every signal/method in the API against Google's public test ad unit IDs (already hardcoded in [`main.gd`](main.gd)) — no real AdMob account needed.

## Prerequisites

Build the addon first (from the repo root):

```sh
make build    # iOS/macOS (Sources/GodotAdMob)
make android  # Android (android/)
```

This copies the built binaries into `demo/addons/GodotAdMob/bin/`. See the root [README](../README.md#building-from-source) for toolchain requirements.

## Run it

`export_presets.cfg` isn't included (it holds your personal Team ID/bundle ID). Copy the template and fill in your own values:

```sh
cp demo/export_presets.cfg.example demo/export_presets.cfg
```

Then in that file:

- **iOS preset:** set `application/app_store_team_id` (your Apple Developer Team ID) and `application/bundle_identifier`. The test AdMob App ID (`GADApplicationIdentifier`) is already in `application/additional_plist_content` — no change needed there.
- **Android preset:** set `package/unique_name` to your own package ID. `gradle_build/use_gradle_build=true` is already set — required for any `.aar`-based Godot Android plugin to load. The test AdMob App ID is injected automatically by `GodotAdMobExportPlugin.gd`.

- **macOS (fastest loop):** open `demo/project.godot` in Godot 4.2+ and run the main scene directly from the editor — no export preset needed.
- **iOS:** export/run via the `iOS` preset on a device or simulator through Xcode.
- **Android:** export a debug APK via the `Android` preset and install it (`adb install`).

## What to expect

On launch, the status label shows "GodotAdMob Initialized" once `Engine.get_singleton("GodotAdMob")` resolves and consent/init complete. Each card (Banner, Interstitial, Rewarded, Rewarded Interstitial, App Open) has Load/Show buttons — Show enables once the matching `_loaded` signal fires. Watch the status labels (or device logs) for `_failed` signals if something's misconfigured.

If the status label reads "GodotAdMob not found", the addon didn't build/export correctly for that platform — recheck the prerequisites step.
