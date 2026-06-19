# GodotAdMob

[![Godot](https://img.shields.io/badge/Godot%20Engine-4.2+-blue.svg)](https://github.com/godotengine/godot/)
[![SwiftGodot](https://img.shields.io/badge/SwiftGodot-pinned-blue.svg)](https://github.com/migueldeicaza/SwiftGodot/)
![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS-333333.svg?style=flat)
![iOS](https://img.shields.io/badge/iOS-17+-green.svg?style=flat)
![macOS](https://img.shields.io/badge/macOS-14+-green.svg?style=flat)
[![Swift](https://img.shields.io/badge/Swift-6-blue.svg)](https://www.swift.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)

Native Google Mobile Ads (AdMob) plugin for Godot 4 on iOS, built with Swift and [SwiftGodotRuntime](https://github.com/migueldeicaza/SwiftGodot). Supports banners, interstitials, rewarded, rewarded interstitial, app open ads, and UMP consent forms (GDPR compliance) — signals go directly to your GDScript.

---

## Requirements

- iOS 17.0 / macOS 14.0
- Godot 4.2+
- [GodotApplePlugins](https://github.com/zt-pawer/GodotApplePlugins) installed — provides the shared `SwiftGodotRuntime` the plugin links against

The plugin also ships empty stubs for Linux and Windows so your project compiles on those platforms without errors. Ad functionality is iOS-only.

---

## Installation

1. Download the latest release zip from [Releases](https://github.com/zt-pawer/GodotAdMob/releases)
2. Unzip and copy `addons/GodotAdMob/` into your Godot project's `addons/`
3. Ensure `addons/GodotApplePluginsRuntime/` is also present (from [GodotApplePlugins](https://github.com/zt-pawer/GodotApplePlugins))
4. Add your AdMob App ID to your iOS `Info.plist`:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
   ```

---

## API

The class is guarded with `ClassDB.class_exists("GodotAdMob")` — it only exists on iOS/macOS. On other platforms the guard simply skips instantiation.

### `GodotAdMob`

#### Quick start

```gdscript
extends Node

var _admob: Object

func _ready() -> void:
    if not ClassDB.class_exists("GodotAdMob"):
        return
    _admob = ClassDB.instantiate("GodotAdMob")

    # Consent
    _admob.consent_info_updated.connect(_on_consent_info_updated)
    _admob.consent_info_failed.connect(_on_consent_info_failed)
    _admob.consent_form_presented.connect(_on_consent_form_presented)
    _admob.consent_form_failed.connect(_on_consent_form_failed)

    # Banner
    _admob.banner_loaded.connect(_on_banner_loaded)
    _admob.banner_failed.connect(_on_banner_failed)

    # Interstitial
    _admob.interstitial_loaded.connect(_on_interstitial_loaded)
    _admob.interstitial_failed.connect(_on_interstitial_failed)
    _admob.interstitial_closed.connect(_on_interstitial_closed)

    # Rewarded
    _admob.rewarded_loaded.connect(_on_rewarded_loaded)
    _admob.rewarded_failed.connect(_on_rewarded_failed)
    _admob.rewarded_earned.connect(_on_rewarded_earned)
    _admob.rewarded_closed.connect(_on_rewarded_closed)

    # 1. Request consent status
    _admob.requestConsentInfoUpdate(false)

# --- Consent ---

func _on_consent_info_updated() -> void:
    if _admob.canRequestAds():
        _admob.initialize()
    else:
        _admob.loadAndPresentConsentForm()

func _on_consent_info_failed(error: String) -> void:
    print("Consent update failed: ", error)
    _admob.initialize()  # fallback

func _on_consent_form_presented() -> void:
    if _admob.canRequestAds():
        _admob.initialize()

func _on_consent_form_failed(error: String) -> void:
    print("Consent form failed: ", error)
    _admob.initialize()  # fallback

# --- Banner ---

func _on_banner_loaded() -> void:
    _admob.showBanner()

func _on_banner_failed(error: String) -> void:
    print("Banner failed: ", error)

# --- Interstitial ---

func _on_interstitial_loaded() -> void:
    _admob.showInterstitial()

func _on_interstitial_failed(error: String) -> void:
    print("Interstitial failed: ", error)

func _on_interstitial_closed() -> void:
    print("Interstitial dismissed")

# --- Rewarded ---

func _on_rewarded_loaded() -> void:
    _admob.showRewarded()

func _on_rewarded_failed(error: String) -> void:
    print("Rewarded failed: ", error)

func _on_rewarded_earned(reward_type: String, reward_amount: int) -> void:
    print("Reward: ", reward_amount, " x ", reward_type)

func _on_rewarded_closed() -> void:
    print("Rewarded dismissed")
```

---

#### Signals

| Signal | Arguments | Description |
|--------|-----------|-------------|
| `banner_loaded` | — | Banner ad loaded successfully |
| `banner_failed` | `error: String` | Banner ad failed to load |
| `interstitial_loaded` | — | Interstitial ad loaded successfully |
| `interstitial_failed` | `error: String` | Interstitial ad failed to load or present |
| `interstitial_closed` | — | Interstitial ad dismissed |
| `rewarded_loaded` | — | Rewarded ad loaded successfully |
| `rewarded_failed` | `error: String` | Rewarded ad failed to load or present |
| `rewarded_earned` | `type: String, amount: int` | User completed the rewarded ad |
| `rewarded_closed` | — | Rewarded ad dismissed |
| `rewarded_interstitial_loaded` | — | Rewarded interstitial loaded |
| `rewarded_interstitial_failed` | `error: String` | Rewarded interstitial failed |
| `rewarded_interstitial_earned` | `type: String, amount: int` | User completed rewarded interstitial |
| `rewarded_interstitial_closed` | — | Rewarded interstitial dismissed |
| `app_open_loaded` | — | App open ad loaded |
| `app_open_failed` | `error: String` | App open ad failed |
| `app_open_closed` | — | App open ad dismissed |
| `consent_info_updated` | — | UMP consent information updated |
| `consent_info_failed` | `error: String` | UMP consent update failed |
| `consent_form_presented` | — | UMP consent form presented and completed |
| `consent_form_failed` | `error: String` | UMP consent form failed to load or present |

---

#### Methods

**Lifecycle**

| Method | Description |
|--------|-------------|
| `initialize()` | Initialise the Google Mobile Ads SDK. Call after consent is obtained |

**Banner**

| Method | Description |
|--------|-------------|
| `loadBanner(adUnitID: String, position: String)` | Load a banner ad. `position` is `"top"` or `"bottom"`. Anchored to the safe area |
| `showBanner()` | Show the loaded banner |
| `hideBanner()` | Hide the banner without destroying it |
| `destroyBanner()` | Remove the banner from the view hierarchy and free it |

**Interstitial**

| Method | Description |
|--------|-------------|
| `loadInterstitial(adUnitID: String)` | Load an interstitial ad |
| `showInterstitial()` | Present the loaded interstitial |

**Rewarded**

| Method | Description |
|--------|-------------|
| `loadRewarded(adUnitID: String)` | Load a rewarded ad |
| `showRewarded()` | Present the loaded rewarded ad |

**Rewarded Interstitial**

| Method | Description |
|--------|-------------|
| `loadRewardedInterstitial(adUnitID: String)` | Load a rewarded interstitial ad |
| `showRewardedInterstitial()` | Present the loaded rewarded interstitial |

**App Open**

| Method | Description |
|--------|-------------|
| `loadAppOpen(adUnitID: String)` | Load an app open ad |
| `showAppOpen()` | Present the loaded app open ad |

**Consent (UMP)**

| Method | Description |
|--------|-------------|
| `requestConsentInfoUpdate(underAgeOfConsent: Bool)` | Request user consent status. Set `true` for COPPA/GDPR child protection |
| `loadAndPresentConsentForm()` | Load and show the UMP consent form if required |
| `canRequestAds() -> bool` | Returns `true` if consent allows requesting ads |
| `resetConsent()` | Reset consent status (useful for testing) |

**Configuration**

| Method | Description |
|--------|-------------|
| `setTestDeviceIDs(deviceIDs: PackedStringArray)` | Register test device IDs to receive test ads |
| `setChildDirectedTreatment(tag: Bool)` | Enable COPPA child-directed treatment |
| `setMaxAdContentRating(rating: String)` | Max content rating: `"g"`, `"pg"`, `"t"`, `"ma"` |
| `setMuted(muted: Bool)` | Mute/unmute ad audio |

---

## Building from Source

Requires Xcode on macOS. Before building, open the package in Xcode and share the scheme (**Product → Manage Schemes → Shared**) so `xcodebuild` can find it.

```bash
make build
make dist
```

`make build` compiles xcframeworks for iOS, iOS Simulator, and macOS. `make dist` assembles the `addons/` folder ready to drop into your Godot project.

---

## SwiftGodot Version

This plugin is pinned to SwiftGodot revision `f528ba67accbe3cca06c1d401c8f9d7c17022f63` — the same revision used by [GodotApplePlugins](https://github.com/zt-pawer/GodotApplePlugins). Both must stay in sync to share `SwiftGodotRuntime.xcframework` without ABI skew.

---

## Contributing

Have a bug fix or feature request? Contributions are welcome!

[How to contribute](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)

---

## Donate and support

[![Buy me a coffee](.github/bmc-button.png)](https://buymeacoffee.com/ztpawer)

[![Become a patreon](.github/patreon-button.png)](https://patreon.com/ztpawer)

---

## Games using it

[![Pang in Time](.github/pit.webp)](https://apps.apple.com/us/app/pang-in-time/id6499503406)

[![Jupiter Escape](.github/je.webp)](https://apps.apple.com/us/app/jupiter-escape/id6476010007)

---

## License

MIT — see [LICENSE](LICENSE)
