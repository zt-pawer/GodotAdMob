package org.godotengine.plugin.godotadmob

import android.util.Log
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

private const val TAG = "GodotAdMob"

// Walking skeleton: every method below is a stub (log + emit the matching
// `_failed` signal, or a safe default for getters) that proves the Kotlin
// GodotPlugin is reachable via Engine.get_singleton("GodotAdMob") through the
// full native-shim + AAR path. Real Google Mobile Ads/UMP logic is a
// follow-up PR (see the Android support tracking issue).
class GodotAdMob(godot: Godot) : GodotPlugin(godot) {

    companion object {
        init {
            System.loadLibrary("GodotAdMob")
        }
    }

    override fun getPluginName() = "GodotAdMob"

    override fun getPluginGDExtensionLibrariesPaths() =
        setOf("res://addons/GodotAdMob/godot_ad_mob.gdextension")

    override fun getPluginSignals(): MutableSet<SignalInfo> = mutableSetOf(
        SignalInfo("banner_loaded"),
        SignalInfo("banner_failed", String::class.java),

        SignalInfo("interstitial_loaded"),
        SignalInfo("interstitial_failed", String::class.java),
        SignalInfo("interstitial_closed"),

        SignalInfo("rewarded_loaded"),
        SignalInfo("rewarded_failed", String::class.java),
        SignalInfo("rewarded_earned", String::class.java, Int::class.java),
        SignalInfo("rewarded_closed"),

        SignalInfo("rewarded_interstitial_loaded"),
        SignalInfo("rewarded_interstitial_failed", String::class.java),
        SignalInfo("rewarded_interstitial_earned", String::class.java, Int::class.java),
        SignalInfo("rewarded_interstitial_closed"),

        SignalInfo("app_open_loaded"),
        SignalInfo("app_open_failed", String::class.java),
        SignalInfo("app_open_closed"),

        SignalInfo("consent_info_updated"),
        SignalInfo("consent_info_failed", String::class.java),
        SignalInfo("consent_form_presented"),
        SignalInfo("consent_form_failed", String::class.java),
    )

    private fun stub(method: String) {
        Log.w(TAG, "$method() is a stub on Android — real ad logic lands in a follow-up PR")
    }

    // --- Lifecycle ---

    @UsedByGodot
    fun initialize() {
        stub("initialize")
    }

    // --- Banner ---

    @UsedByGodot
    fun loadBanner(adUnitID: String, position: String, adaptive: Boolean) {
        stub("loadBanner")
        emitSignal("banner_failed", "Android ad loading not implemented yet")
    }

    @UsedByGodot
    fun showBanner() {
        stub("showBanner")
    }

    @UsedByGodot
    fun hideBanner() {
        stub("hideBanner")
    }

    @UsedByGodot
    fun destroyBanner() {
        stub("destroyBanner")
    }

    // --- Interstitial ---

    @UsedByGodot
    fun loadInterstitial(adUnitID: String) {
        stub("loadInterstitial")
        emitSignal("interstitial_failed", "Android ad loading not implemented yet")
    }

    @UsedByGodot
    fun showInterstitial() {
        stub("showInterstitial")
        emitSignal("interstitial_failed", "No interstitial ad loaded")
    }

    // --- Rewarded ---

    @UsedByGodot
    fun loadRewarded(adUnitID: String) {
        stub("loadRewarded")
        emitSignal("rewarded_failed", "Android ad loading not implemented yet")
    }

    @UsedByGodot
    fun setRewardedCustomData(customData: String) {
        stub("setRewardedCustomData")
    }

    @UsedByGodot
    fun showRewarded() {
        stub("showRewarded")
        emitSignal("rewarded_failed", "No rewarded ad loaded")
    }

    // --- Rewarded Interstitial ---

    @UsedByGodot
    fun loadRewardedInterstitial(adUnitID: String) {
        stub("loadRewardedInterstitial")
        emitSignal("rewarded_interstitial_failed", "Android ad loading not implemented yet")
    }

    @UsedByGodot
    fun showRewardedInterstitial() {
        stub("showRewardedInterstitial")
        emitSignal("rewarded_interstitial_failed", "No rewarded interstitial ad loaded")
    }

    // --- App Open ---

    @UsedByGodot
    fun loadAppOpen(adUnitID: String) {
        stub("loadAppOpen")
        emitSignal("app_open_failed", "Android ad loading not implemented yet")
    }

    @UsedByGodot
    fun showAppOpen() {
        stub("showAppOpen")
        emitSignal("app_open_failed", "No app open ad loaded")
    }

    // --- Consent ---

    @UsedByGodot
    fun requestConsentInfoUpdate(underAgeOfConsent: Boolean) {
        stub("requestConsentInfoUpdate")
        emitSignal("consent_info_failed", "Android consent flow not implemented yet")
    }

    @UsedByGodot
    fun loadAndPresentConsentForm() {
        stub("loadAndPresentConsentForm")
        emitSignal("consent_form_failed", "Android consent flow not implemented yet")
    }

    @UsedByGodot
    fun canRequestAds(): Boolean {
        stub("canRequestAds")
        return false
    }

    @UsedByGodot
    fun resetConsent() {
        stub("resetConsent")
    }

    // --- Config ---

    @UsedByGodot
    fun setTestDeviceIDs(deviceIDs: Array<String>) {
        stub("setTestDeviceIDs")
    }

    @UsedByGodot
    fun setChildDirectedTreatment(tag: Boolean) {
        stub("setChildDirectedTreatment")
    }

    @UsedByGodot
    fun setMaxAdContentRating(rating: String) {
        stub("setMaxAdContentRating")
    }

    @UsedByGodot
    fun setMuted(muted: Boolean) {
        stub("setMuted")
    }

    @UsedByGodot
    fun setVolume(volume: Float) {
        stub("setVolume")
    }

    @UsedByGodot
    fun presentAdInspector() {
        stub("presentAdInspector")
    }
}
