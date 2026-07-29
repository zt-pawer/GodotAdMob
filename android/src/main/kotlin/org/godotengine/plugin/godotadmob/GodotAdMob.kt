package org.godotengine.plugin.godotadmob

import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.gms.ads.appopen.AppOpenAd
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
import com.google.android.gms.ads.rewarded.RewardItem
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAd
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAdLoadCallback
import com.google.android.ump.ConsentDebugSettings
import com.google.android.ump.ConsentForm
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.FormError
import com.google.android.ump.UserMessagingPlatform
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

private const val TAG = "GodotAdMob"

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
        // Int::class.javaObjectType (java.lang.Integer), not Int::class.java (primitive int):
        // emitSignal()'s isInstance() check against a primitive Class always returns false
        // since vararg args are boxed at the call site.
        SignalInfo("rewarded_earned", String::class.java, Int::class.javaObjectType),
        SignalInfo("rewarded_closed"),

        SignalInfo("rewarded_interstitial_loaded"),
        SignalInfo("rewarded_interstitial_failed", String::class.java),
        SignalInfo("rewarded_interstitial_earned", String::class.java, Int::class.javaObjectType),
        SignalInfo("rewarded_interstitial_closed"),

        SignalInfo("app_open_loaded"),
        SignalInfo("app_open_failed", String::class.java),
        SignalInfo("app_open_closed"),

        SignalInfo("consent_info_updated"),
        SignalInfo("consent_info_failed", String::class.java),
        SignalInfo("consent_form_presented"),
        SignalInfo("consent_form_failed", String::class.java),
    )

    private var bannerView: AdView? = null
    private var bannerContainer: FrameLayout? = null
    private var interstitialAd: InterstitialAd? = null
    private var rewardedAd: RewardedAd? = null
    private var rewardedInterstitialAd: RewardedInterstitialAd? = null
    private var appOpenAd: AppOpenAd? = null
    private var testDeviceIDs: List<String> = emptyList()
    private var pendingSSVCustomData: String = "" // Set by GDScript before showRewarded()

    // --- Lifecycle ---

    @UsedByGodot
    fun initialize() {
        val activity = getActivity() ?: return
        runOnHostThread {
            MobileAds.initialize(activity) {}
        }
    }

    // --- Banner ---

    @UsedByGodot
    fun loadBanner(adUnitID: String, position: String, adaptive: Boolean) {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("banner_failed", "No activity found")
            return
        }
        runOnHostThread {
            destroyBannerInternal()

            val adSize = if (adaptive) {
                val metrics = activity.resources.displayMetrics
                val widthDp = (metrics.widthPixels / metrics.density).toInt()
                AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp)
            } else {
                AdSize.BANNER
            }

            val adView = AdView(activity)
            adView.adUnitId = adUnitID
            adView.setAdSize(adSize)
            adView.visibility = View.INVISIBLE
            adView.adListener = object : AdListener() {
                override fun onAdLoaded() {
                    emitSignal("banner_loaded")
                }
                override fun onAdFailedToLoad(error: LoadAdError) {
                    emitSignal("banner_failed", error.message)
                }
            }
            bannerView = adView

            val container = FrameLayout(activity)
            val gravity = if (position == "top") {
                Gravity.TOP or Gravity.CENTER_HORIZONTAL
            } else {
                Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            }
            container.addView(
                adView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    gravity,
                ),
            )
            bannerContainer = container

            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.addView(
                container,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )

            adView.loadAd(AdRequest.Builder().build())
        }
    }

    @UsedByGodot
    fun showBanner() {
        runOnHostThread { bannerView?.visibility = View.VISIBLE }
    }

    @UsedByGodot
    fun hideBanner() {
        runOnHostThread { bannerView?.visibility = View.INVISIBLE }
    }

    @UsedByGodot
    fun destroyBanner() {
        runOnHostThread { destroyBannerInternal() }
    }

    private fun destroyBannerInternal() {
        bannerContainer?.let { container -> (container.parent as? ViewGroup)?.removeView(container) }
        bannerView?.destroy()
        bannerView = null
        bannerContainer = null
    }

    // --- Interstitial ---

    @UsedByGodot
    fun loadInterstitial(adUnitID: String) {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("interstitial_failed", "No activity found")
            return
        }
        runOnHostThread {
            InterstitialAd.load(
                activity,
                adUnitID,
                AdRequest.Builder().build(),
                object : InterstitialAdLoadCallback() {
                    override fun onAdLoaded(ad: InterstitialAd) {
                        interstitialAd = ad
                        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                            override fun onAdDismissedFullScreenContent() {
                                interstitialAd = null
                                emitSignal("interstitial_closed")
                            }
                            override fun onAdFailedToShowFullScreenContent(adError: AdError) {
                                interstitialAd = null
                                emitSignal("interstitial_failed", adError.message)
                            }
                        }
                        emitSignal("interstitial_loaded")
                    }
                    override fun onAdFailedToLoad(error: LoadAdError) {
                        emitSignal("interstitial_failed", error.message)
                    }
                },
            )
        }
    }

    @UsedByGodot
    fun showInterstitial() {
        val ad = interstitialAd
        val activity = getActivity()
        if (ad == null) {
            emitSignal("interstitial_failed", "No interstitial ad loaded")
            return
        }
        if (activity == null) {
            emitSignal("interstitial_failed", "No activity found")
            return
        }
        runOnHostThread { ad.show(activity) }
    }

    // --- Rewarded ---

    @UsedByGodot
    fun loadRewarded(adUnitID: String) {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("rewarded_failed", "No activity found")
            return
        }
        runOnHostThread {
            RewardedAd.load(
                activity,
                adUnitID,
                AdRequest.Builder().build(),
                object : RewardedAdLoadCallback() {
                    override fun onAdLoaded(ad: RewardedAd) {
                        rewardedAd = ad
                        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                            override fun onAdDismissedFullScreenContent() {
                                rewardedAd = null
                                emitSignal("rewarded_closed")
                            }
                            override fun onAdFailedToShowFullScreenContent(adError: AdError) {
                                rewardedAd = null
                                emitSignal("rewarded_failed", adError.message)
                            }
                        }
                        emitSignal("rewarded_loaded")
                    }
                    override fun onAdFailedToLoad(error: LoadAdError) {
                        emitSignal("rewarded_failed", error.message)
                    }
                },
            )
        }
    }

    // setRewardedCustomData must be called before showRewarded(). The customData string
    // (client nonce) is sent to AdMob as SSV custom_data, arriving at the verification
    // endpoint as the `custom_data` query param.
    @UsedByGodot
    fun setRewardedCustomData(customData: String) {
        pendingSSVCustomData = customData
    }

    @UsedByGodot
    fun showRewarded() {
        val ad = rewardedAd
        val activity = getActivity()
        if (ad == null) {
            emitSignal("rewarded_failed", "No rewarded ad loaded")
            return
        }
        if (activity == null) {
            emitSignal("rewarded_failed", "No activity found")
            return
        }
        runOnHostThread {
            if (pendingSSVCustomData.isNotEmpty()) {
                ad.setServerSideVerificationOptions(
                    ServerSideVerificationOptions.Builder().setCustomData(pendingSSVCustomData).build(),
                )
                pendingSSVCustomData = ""
            }
            ad.show(activity) { rewardItem: RewardItem ->
                emitSignal("rewarded_earned", rewardItem.type, rewardItem.amount)
            }
        }
    }

    // --- Rewarded Interstitial ---

    @UsedByGodot
    fun loadRewardedInterstitial(adUnitID: String) {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("rewarded_interstitial_failed", "No activity found")
            return
        }
        runOnHostThread {
            RewardedInterstitialAd.load(
                activity,
                adUnitID,
                AdRequest.Builder().build(),
                object : RewardedInterstitialAdLoadCallback() {
                    override fun onAdLoaded(ad: RewardedInterstitialAd) {
                        rewardedInterstitialAd = ad
                        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                            override fun onAdDismissedFullScreenContent() {
                                rewardedInterstitialAd = null
                                emitSignal("rewarded_interstitial_closed")
                            }
                            override fun onAdFailedToShowFullScreenContent(adError: AdError) {
                                rewardedInterstitialAd = null
                                emitSignal("rewarded_interstitial_failed", adError.message)
                            }
                        }
                        emitSignal("rewarded_interstitial_loaded")
                    }
                    override fun onAdFailedToLoad(error: LoadAdError) {
                        emitSignal("rewarded_interstitial_failed", error.message)
                    }
                },
            )
        }
    }

    @UsedByGodot
    fun showRewardedInterstitial() {
        val ad = rewardedInterstitialAd
        val activity = getActivity()
        if (ad == null) {
            emitSignal("rewarded_interstitial_failed", "No rewarded interstitial ad loaded")
            return
        }
        if (activity == null) {
            emitSignal("rewarded_interstitial_failed", "No activity found")
            return
        }
        runOnHostThread {
            ad.show(activity) { rewardItem: RewardItem ->
                emitSignal("rewarded_interstitial_earned", rewardItem.type, rewardItem.amount)
            }
        }
    }

    // --- App Open ---

    @UsedByGodot
    fun loadAppOpen(adUnitID: String) {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("app_open_failed", "No activity found")
            return
        }
        runOnHostThread {
            AppOpenAd.load(
                activity,
                adUnitID,
                AdRequest.Builder().build(),
                object : AppOpenAd.AppOpenAdLoadCallback() {
                    override fun onAdLoaded(ad: AppOpenAd) {
                        appOpenAd = ad
                        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                            override fun onAdDismissedFullScreenContent() {
                                appOpenAd = null
                                emitSignal("app_open_closed")
                            }
                            override fun onAdFailedToShowFullScreenContent(adError: AdError) {
                                appOpenAd = null
                                emitSignal("app_open_failed", adError.message)
                            }
                        }
                        emitSignal("app_open_loaded")
                    }
                    override fun onAdFailedToLoad(error: LoadAdError) {
                        emitSignal("app_open_failed", error.message)
                    }
                },
            )
        }
    }

    @UsedByGodot
    fun showAppOpen() {
        val ad = appOpenAd
        val activity = getActivity()
        if (ad == null) {
            emitSignal("app_open_failed", "No app open ad loaded")
            return
        }
        if (activity == null) {
            emitSignal("app_open_failed", "No activity found")
            return
        }
        runOnHostThread { ad.show(activity) }
    }

    // --- Consent ---

    @UsedByGodot
    fun requestConsentInfoUpdate(underAgeOfConsent: Boolean) {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("consent_info_failed", "No activity found")
            return
        }
        runOnHostThread {
            val paramsBuilder = ConsentRequestParameters.Builder()
                .setTagForUnderAgeOfConsent(underAgeOfConsent)
            if (testDeviceIDs.isNotEmpty()) {
                val debugSettings = ConsentDebugSettings.Builder(activity)
                    .setDebugGeography(ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA)
                testDeviceIDs.forEach { debugSettings.addTestDeviceHashedId(it) }
                paramsBuilder.setConsentDebugSettings(debugSettings.build())
            }
            UserMessagingPlatform.getConsentInformation(activity).requestConsentInfoUpdate(
                activity,
                paramsBuilder.build(),
                { emitSignal("consent_info_updated") },
                { error: FormError -> emitSignal("consent_info_failed", error.message) },
            )
        }
    }

    @UsedByGodot
    fun loadAndPresentConsentForm() {
        val activity = getActivity()
        if (activity == null) {
            emitSignal("consent_form_failed", "No activity found")
            return
        }
        runOnHostThread {
            UserMessagingPlatform.loadConsentForm(
                activity,
                { form: ConsentForm ->
                    val status = UserMessagingPlatform.getConsentInformation(activity).consentStatus
                    if (status == ConsentInformation.ConsentStatus.REQUIRED) {
                        form.show(activity) { dismissError: FormError? ->
                            if (dismissError != null) {
                                emitSignal("consent_form_failed", dismissError.message)
                            } else {
                                emitSignal("consent_form_presented")
                            }
                        }
                    } else {
                        emitSignal("consent_form_presented")
                    }
                },
                { error: FormError -> emitSignal("consent_form_failed", error.message) },
            )
        }
    }

    @UsedByGodot
    fun canRequestAds(): Boolean {
        val activity = getActivity() ?: return false
        return UserMessagingPlatform.getConsentInformation(activity).canRequestAds()
    }

    @UsedByGodot
    fun resetConsent() {
        val activity = getActivity() ?: return
        UserMessagingPlatform.getConsentInformation(activity).reset()
    }

    // --- Config ---

    @UsedByGodot
    fun setTestDeviceIDs(deviceIDs: Array<String>) {
        testDeviceIDs = deviceIDs.toList()
        updateRequestConfiguration { setTestDeviceIds(testDeviceIDs) }
    }

    @UsedByGodot
    fun setChildDirectedTreatment(tag: Boolean) {
        updateRequestConfiguration {
            setTagForChildDirectedTreatment(
                if (tag) {
                    RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE
                } else {
                    RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_FALSE
                },
            )
        }
    }

    @UsedByGodot
    fun setMaxAdContentRating(rating: String) {
        val value = when (rating.lowercase()) {
            "g" -> RequestConfiguration.MAX_AD_CONTENT_RATING_G
            "pg" -> RequestConfiguration.MAX_AD_CONTENT_RATING_PG
            "t" -> RequestConfiguration.MAX_AD_CONTENT_RATING_T
            "ma" -> RequestConfiguration.MAX_AD_CONTENT_RATING_MA
            else -> return
        }
        updateRequestConfiguration { setMaxAdContentRating(value) }
    }

    private fun updateRequestConfiguration(block: RequestConfiguration.Builder.() -> Unit) {
        val current = MobileAds.getRequestConfiguration()
        val builder = RequestConfiguration.Builder()
            .setTestDeviceIds(current.testDeviceIds)
            .setTagForChildDirectedTreatment(current.tagForChildDirectedTreatment)
            .setTagForUnderAgeOfConsent(current.tagForUnderAgeOfConsent)
            .setMaxAdContentRating(current.maxAdContentRating)
        builder.block()
        MobileAds.setRequestConfiguration(builder.build())
    }

    @UsedByGodot
    fun setMuted(muted: Boolean) {
        MobileAds.setAppMuted(muted)
    }

    @UsedByGodot
    fun setVolume(volume: Float) {
        MobileAds.setAppVolume(volume)
    }

    @UsedByGodot
    fun presentAdInspector() {
        val activity = getActivity() ?: return
        runOnHostThread {
            MobileAds.openAdInspector(activity) { error ->
                if (error != null) Log.e(TAG, "Ad Inspector error: ${error.message}")
            }
        }
    }
}
