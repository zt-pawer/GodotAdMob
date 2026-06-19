@preconcurrency import SwiftGodotRuntime
import Foundation
#if os(iOS)
import UIKit
import GoogleMobileAds
import UserMessagingPlatform
#endif

@Godot
class GodotAdMob: RefCounted, @unchecked Sendable {

    // MARK: - Signals

    @Signal var banner_loaded: SimpleSignal
    @Signal var banner_failed: SignalWithArguments<String>

    @Signal var interstitial_loaded: SimpleSignal
    @Signal var interstitial_failed: SignalWithArguments<String>
    @Signal var interstitial_closed: SimpleSignal

    @Signal var rewarded_loaded: SimpleSignal
    @Signal var rewarded_failed: SignalWithArguments<String>
    @Signal var rewarded_earned: SignalWithArguments<String, Int>
    @Signal var rewarded_closed: SimpleSignal

    @Signal var rewarded_interstitial_loaded: SimpleSignal
    @Signal var rewarded_interstitial_failed: SignalWithArguments<String>
    @Signal var rewarded_interstitial_earned: SignalWithArguments<String, Int>
    @Signal var rewarded_interstitial_closed: SimpleSignal

    @Signal var app_open_loaded: SimpleSignal
    @Signal var app_open_failed: SignalWithArguments<String>
    @Signal var app_open_closed: SimpleSignal

    @Signal var consent_info_updated: SimpleSignal
    @Signal var consent_info_failed: SignalWithArguments<String>
    @Signal var consent_form_presented: SimpleSignal
    @Signal var consent_form_failed: SignalWithArguments<String>

    // MARK: - iOS-only state

#if os(iOS)
    var bannerView: GADBannerView?
    var bannerPosition: String = "bottom"
    var interstitialAd: GADInterstitialAd?
    var rewardedAd: GADRewardedAd?
    var rewardedInterstitialAd: GADRewardedInterstitialAd?
    var appOpenAd: GADAppOpenAd?
    var adDelegate: AdDelegate?
    var testDeviceIDs: [String] = []

    var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first { $0.isKeyWindow }?
            .rootViewController
    }

    var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first { $0.isKeyWindow }
    }
#endif

    // MARK: - Init

    @Callable
    func initialize() {
#if os(iOS)
        let delegate = AdDelegate(self)
        adDelegate = delegate
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        print("[GodotAdMob] initialized")
#endif
    }

    // MARK: - Banner

    @Callable
    func loadBanner(adUnitID: String, position: String) {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let root = self.rootViewController, let window = self.keyWindow else {
                self.banner_failed.emit("No root view controller or key window found")
                return
            }
            self.bannerView?.removeFromSuperview()
            self.bannerView = nil

            let banner = GADBannerView(adSize: GADAdSizeBanner)
            banner.adUnitID = adUnitID
            banner.rootViewController = root
            banner.delegate = self.adDelegate
            banner.isHidden = true
            self.bannerView = banner
            self.bannerPosition = position

            window.addSubview(banner)
            banner.translatesAutoresizingMaskIntoConstraints = false
            let guide = window.safeAreaLayoutGuide
            var constraints = [banner.centerXAnchor.constraint(equalTo: window.centerXAnchor)]
            if position == "top" {
                constraints.append(banner.topAnchor.constraint(equalTo: guide.topAnchor))
            } else {
                constraints.append(banner.bottomAnchor.constraint(equalTo: guide.bottomAnchor))
            }
            NSLayoutConstraint.activate(constraints)
            banner.load(GADRequest())
        }
#endif
    }

    @Callable
    func showBanner() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in self?.bannerView?.isHidden = false }
#endif
    }

    @Callable
    func hideBanner() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in self?.bannerView?.isHidden = true }
#endif
    }

    @Callable
    func destroyBanner() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            self?.bannerView?.removeFromSuperview()
            self?.bannerView = nil
        }
#endif
    }

    // MARK: - Interstitial

    @Callable
    func loadInterstitial(adUnitID: String) {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // GAD completion fires on main thread — no inner dispatch needed
            GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
                guard let self else { return }
                if let msg = error?.localizedDescription {
                    self.interstitial_failed.emit(msg)
                } else if let ad {
                    self.interstitialAd = ad
                    self.interstitialAd?.fullScreenContentDelegate = self.adDelegate
                    self.interstitial_loaded.emit()
                }
            }
        }
#endif
    }

    @Callable
    func showInterstitial() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let ad = self.interstitialAd else {
                self.interstitial_failed.emit("No interstitial ad loaded"); return
            }
            guard let root = self.rootViewController else {
                self.interstitial_failed.emit("No root view controller"); return
            }
            ad.present(fromRootViewController: root)
        }
#endif
    }

    // MARK: - Rewarded

    @Callable
    func loadRewarded(adUnitID: String) {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
                guard let self else { return }
                if let msg = error?.localizedDescription {
                    self.rewarded_failed.emit(msg)
                } else if let ad {
                    self.rewardedAd = ad
                    self.rewardedAd?.fullScreenContentDelegate = self.adDelegate
                    self.rewarded_loaded.emit()
                }
            }
        }
#endif
    }

    @Callable
    func showRewarded() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let ad = self.rewardedAd else {
                self.rewarded_failed.emit("No rewarded ad loaded"); return
            }
            guard let root = self.rootViewController else {
                self.rewarded_failed.emit("No root view controller"); return
            }
            ad.present(fromRootViewController: root) { [weak self] in
                guard let self else { return }
                let reward = ad.adReward
                self.rewarded_earned.emit(reward.type, Int(truncating: reward.amount))
            }
        }
#endif
    }

    // MARK: - Rewarded Interstitial

    @Callable
    func loadRewardedInterstitial(adUnitID: String) {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            GADRewardedInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
                guard let self else { return }
                if let msg = error?.localizedDescription {
                    self.rewarded_interstitial_failed.emit(msg)
                } else if let ad {
                    self.rewardedInterstitialAd = ad
                    self.rewardedInterstitialAd?.fullScreenContentDelegate = self.adDelegate
                    self.rewarded_interstitial_loaded.emit()
                }
            }
        }
#endif
    }

    @Callable
    func showRewardedInterstitial() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let ad = self.rewardedInterstitialAd else {
                self.rewarded_interstitial_failed.emit("No rewarded interstitial ad loaded"); return
            }
            guard let root = self.rootViewController else {
                self.rewarded_interstitial_failed.emit("No root view controller"); return
            }
            ad.present(fromRootViewController: root) { [weak self] in
                guard let self else { return }
                let reward = ad.adReward
                self.rewarded_interstitial_earned.emit(reward.type, Int(truncating: reward.amount))
            }
        }
#endif
    }

    // MARK: - App Open

    @Callable
    func loadAppOpen(adUnitID: String) {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            GADAppOpenAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
                guard let self else { return }
                if let msg = error?.localizedDescription {
                    self.app_open_failed.emit(msg)
                } else if let ad {
                    self.appOpenAd = ad
                    self.appOpenAd?.fullScreenContentDelegate = self.adDelegate
                    self.app_open_loaded.emit()
                }
            }
        }
#endif
    }

    @Callable
    func showAppOpen() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let ad = self.appOpenAd else {
                self.app_open_failed.emit("No app open ad loaded"); return
            }
            guard let root = self.rootViewController else {
                self.app_open_failed.emit("No root view controller"); return
            }
            ad.present(fromRootViewController: root)
        }
#endif
    }

    // MARK: - Consent

    @Callable
    func requestConsentInfoUpdate(underAgeOfConsent: Bool) {
#if os(iOS)
        let params = UMPRequestParameters()
        params.tagForUnderAgeOfConsent = underAgeOfConsent
        if !testDeviceIDs.isEmpty {
            let debug = UMPDebugSettings()
            debug.testDeviceIdentifiers = testDeviceIDs
            debug.geography = .EEA
            params.debugSettings = debug
        }
        // UMP fires completion on main thread
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: params) { [weak self] error in
            guard let self else { return }
            if let msg = error?.localizedDescription { self.consent_info_failed.emit(msg) }
            else { self.consent_info_updated.emit() }
        }
#endif
    }

    @Callable
    func loadAndPresentConsentForm() {
#if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self, let root = self.rootViewController else {
                self?.consent_form_failed.emit("No root view controller"); return
            }
            // UMP fires completion on main thread
            UMPConsentForm.loadAndPresentIfRequired(from: root) { [weak self] error in
                guard let self else { return }
                if let msg = error?.localizedDescription { self.consent_form_failed.emit(msg) }
                else { self.consent_form_presented.emit() }
            }
        }
#endif
    }

    @Callable
    func canRequestAds() -> Bool {
#if os(iOS)
        return UMPConsentInformation.sharedInstance.canRequestAds
#else
        return false
#endif
    }

    @Callable
    func resetConsent() {
#if os(iOS)
        UMPConsentInformation.sharedInstance.reset()
#endif
    }

    // MARK: - Config

    @Callable
    func setTestDeviceIDs(deviceIDs: PackedStringArray) {
#if os(iOS)
        let ids = deviceIDs.map { String($0) }
        testDeviceIDs = ids
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ids
#endif
    }

    @Callable
    func setChildDirectedTreatment(tag: Bool) {
#if os(iOS)
        GADMobileAds.sharedInstance().requestConfiguration.tagForChildDirectedTreatment = NSNumber(value: tag)
#endif
    }

    @Callable
    func setMaxAdContentRating(rating: String) {
#if os(iOS)
        let value: GADMaxAdContentRating
        switch rating.lowercased() {
        case "g":  value = .general
        case "pg": value = .parentalGuidance
        case "t":  value = .teen
        case "ma": value = .matureAudience
        default:   return
        }
        GADMobileAds.sharedInstance().requestConfiguration.maxAdContentRating = value
#endif
    }

    @Callable
    func setMuted(muted: Bool) {
#if os(iOS)
        GADMobileAds.sharedInstance().applicationMuted = muted
#endif
    }
}

// MARK: - Ad Delegate (UIKit proxy)

#if os(iOS)
class AdDelegate: NSObject, GADBannerViewDelegate, GADFullScreenContentDelegate {
    weak var base: GodotAdMob?

    init(_ base: GodotAdMob) { self.base = base }

    // Banner — GAD fires delegate on main thread
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        base?.banner_loaded.emit()
    }
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        let msg = error.localizedDescription
        base?.banner_failed.emit(msg)
    }

    // Full screen dismissed — GAD fires on main thread
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        guard let base else { return }
        if ad is GADInterstitialAd {
            base.interstitialAd = nil
            base.interstitial_closed.emit()
        } else if ad is GADRewardedAd {
            base.rewardedAd = nil
            base.rewarded_closed.emit()
        } else if ad is GADAppOpenAd {
            base.appOpenAd = nil
            base.app_open_closed.emit()
        } else if ad is GADRewardedInterstitialAd {
            base.rewardedInterstitialAd = nil
            base.rewarded_interstitial_closed.emit()
        }
    }

    // Full screen failed to present — GAD fires on main thread
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let base else { return }
        let msg = error.localizedDescription
        if ad is GADInterstitialAd {
            base.interstitialAd = nil
            base.interstitial_failed.emit(msg)
        } else if ad is GADRewardedAd {
            base.rewardedAd = nil
            base.rewarded_failed.emit(msg)
        } else if ad is GADAppOpenAd {
            base.appOpenAd = nil
            base.app_open_failed.emit(msg)
        } else if ad is GADRewardedInterstitialAd {
            base.rewardedInterstitialAd = nil
            base.rewarded_interstitial_failed.emit(msg)
        }
    }
}
#endif
