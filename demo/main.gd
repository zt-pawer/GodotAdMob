extends Node

var _admob: Object

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var consent_status: Label = $VBoxContainer/ConsentStatus
@onready var banner_status: Label = $VBoxContainer/BannerStatus
@onready var interstitial_status: Label = $VBoxContainer/InterstitialStatus
@onready var rewarded_status: Label = $VBoxContainer/RewardedStatus
@onready var rewarded_interstitial_status: Label = $VBoxContainer/RewardedInterstitialStatus
@onready var app_open_status: Label = $VBoxContainer/AppOpenStatus

@onready var show_banner_btn: Button = $VBoxContainer/HBoxBanner/ShowBanner
@onready var show_interstitial_btn: Button = $VBoxContainer/HBoxInterstitial/ShowInterstitial
@onready var show_rewarded_btn: Button = $VBoxContainer/HBoxRewarded/ShowRewarded
@onready var show_rewarded_interstitial_btn: Button = $VBoxContainer/HBoxRewardedInterstitial/ShowRewardedInterstitial
@onready var show_app_open_btn: Button = $VBoxContainer/HBoxAppOpen/ShowAppOpen

# Google test Ad Unit IDs
const BANNER_AD_UNIT_ID = "ca-app-pub-3940256099942544/2934735716"
const INTERSTITIAL_AD_UNIT_ID = "ca-app-pub-3940256099942544/4411468910"
const REWARDED_AD_UNIT_ID = "ca-app-pub-3940256099942544/1712485313"
const REWARDED_INTERSTITIAL_AD_UNIT_ID = "ca-app-pub-3940256099942544/6978759866"
const APP_OPEN_AD_UNIT_ID = "ca-app-pub-3940256099942544/5575463023"

func _ready() -> void:
	show_banner_btn.disabled = true
	show_interstitial_btn.disabled = true
	show_rewarded_btn.disabled = true
	show_rewarded_interstitial_btn.disabled = true
	show_app_open_btn.disabled = true

	if ClassDB.class_exists("GodotAdMob"):
		_admob = ClassDB.instantiate("GodotAdMob")

		_admob.consent_info_updated.connect(_on_consent_info_updated)
		_admob.consent_info_failed.connect(_on_consent_info_failed)
		_admob.consent_form_presented.connect(_on_consent_form_presented)
		_admob.consent_form_failed.connect(_on_consent_form_failed)

		_admob.banner_loaded.connect(_on_banner_loaded)
		_admob.banner_failed.connect(_on_banner_failed)

		_admob.interstitial_loaded.connect(_on_interstitial_loaded)
		_admob.interstitial_failed.connect(_on_interstitial_failed)
		_admob.interstitial_closed.connect(_on_interstitial_closed)

		_admob.rewarded_loaded.connect(_on_rewarded_loaded)
		_admob.rewarded_failed.connect(_on_rewarded_failed)
		_admob.rewarded_earned.connect(_on_rewarded_earned)
		_admob.rewarded_closed.connect(_on_rewarded_closed)

		_admob.rewarded_interstitial_loaded.connect(_on_rewarded_interstitial_loaded)
		_admob.rewarded_interstitial_failed.connect(_on_rewarded_interstitial_failed)
		_admob.rewarded_interstitial_earned.connect(_on_rewarded_interstitial_earned)
		_admob.rewarded_interstitial_closed.connect(_on_rewarded_interstitial_closed)

		_admob.app_open_loaded.connect(_on_app_open_loaded)
		_admob.app_open_failed.connect(_on_app_open_failed)
		_admob.app_open_closed.connect(_on_app_open_closed)

		_admob.setTestDeviceIDs(PackedStringArray(["375D24F7-0F1E-49EF-B9FD-F27781E0FD0C"]))
		_admob.initialize()
		_admob.setVolume(0.5)
		status_label.text = "GodotAdMob Initialized"
	else:
		status_label.text = "GodotAdMob not found (iOS only)"

# Consent
func _on_consent_info_updated() -> void:
	consent_status.text = "Consent Updated. Can Request Ads: " + str(_admob.canRequestAds())

func _on_consent_info_failed(error_message: String) -> void:
	consent_status.text = "Consent Failed: " + error_message

func _on_consent_form_presented() -> void:
	consent_status.text = "Consent Form Done. Can Request Ads: " + str(_admob.canRequestAds())

func _on_consent_form_failed(error_message: String) -> void:
	consent_status.text = "Consent Form Failed: " + error_message

# Banner
func _on_banner_loaded() -> void:
	banner_status.text = "Banner: Loaded"
	show_banner_btn.disabled = false

func _on_banner_failed(error_message: String) -> void:
	banner_status.text = "Banner Failed: " + error_message
	show_banner_btn.disabled = true

# Interstitial
func _on_interstitial_loaded() -> void:
	interstitial_status.text = "Interstitial: Loaded"
	show_interstitial_btn.disabled = false

func _on_interstitial_failed(error_message: String) -> void:
	interstitial_status.text = "Interstitial Failed: " + error_message
	show_interstitial_btn.disabled = true

func _on_interstitial_closed() -> void:
	interstitial_status.text = "Interstitial: Closed"
	show_interstitial_btn.disabled = true

# Rewarded
func _on_rewarded_loaded() -> void:
	rewarded_status.text = "Rewarded: Loaded"
	show_rewarded_btn.disabled = false

func _on_rewarded_failed(error_message: String) -> void:
	rewarded_status.text = "Rewarded Failed: " + error_message
	show_rewarded_btn.disabled = true

func _on_rewarded_earned(reward_type: String, reward_amount: int) -> void:
	rewarded_status.text = "Rewarded: %d %s" % [reward_amount, reward_type]

func _on_rewarded_closed() -> void:
	rewarded_status.text = "Rewarded: Closed"
	show_rewarded_btn.disabled = true

# Rewarded Interstitial
func _on_rewarded_interstitial_loaded() -> void:
	rewarded_interstitial_status.text = "Rewarded Interstitial: Loaded"
	show_rewarded_interstitial_btn.disabled = false

func _on_rewarded_interstitial_failed(error_message: String) -> void:
	rewarded_interstitial_status.text = "Rewarded Interstitial Failed: " + error_message
	show_rewarded_interstitial_btn.disabled = true

func _on_rewarded_interstitial_earned(reward_type: String, reward_amount: int) -> void:
	rewarded_interstitial_status.text = "Rewarded Interstitial: %d %s" % [reward_amount, reward_type]

func _on_rewarded_interstitial_closed() -> void:
	rewarded_interstitial_status.text = "Rewarded Interstitial: Closed"
	show_rewarded_interstitial_btn.disabled = true

# App Open
func _on_app_open_loaded() -> void:
	app_open_status.text = "App Open: Loaded"
	show_app_open_btn.disabled = false

func _on_app_open_failed(error_message: String) -> void:
	app_open_status.text = "App Open Failed: " + error_message
	show_app_open_btn.disabled = true

func _on_app_open_closed() -> void:
	app_open_status.text = "App Open: Closed"
	show_app_open_btn.disabled = true

# Button handlers — Consent
func _on_request_consent_pressed() -> void:
	if _admob:
		consent_status.text = "Requesting Consent..."
		_admob.requestConsentInfoUpdate(false)

func _on_show_consent_form_pressed() -> void:
	if _admob:
		_admob.loadAndPresentConsentForm()

func _on_reset_consent_pressed() -> void:
	if _admob:
		_admob.resetConsent()
		consent_status.text = "Consent Reset"

# Button handlers — Banner
func _on_load_banner_pressed() -> void:
	if _admob:
		banner_status.text = "Banner: Loading..."
		_admob.loadBanner(BANNER_AD_UNIT_ID, "bottom", true)

func _on_show_banner_pressed() -> void:
	if _admob: _admob.showBanner()

func _on_hide_banner_pressed() -> void:
	if _admob: _admob.hideBanner()

func _on_destroy_banner_pressed() -> void:
	if _admob:
		_admob.destroyBanner()
		banner_status.text = "Banner: Destroyed"
		show_banner_btn.disabled = true

# Button handlers — Interstitial
func _on_load_interstitial_pressed() -> void:
	if _admob:
		interstitial_status.text = "Interstitial: Loading..."
		_admob.loadInterstitial(INTERSTITIAL_AD_UNIT_ID)

func _on_show_interstitial_pressed() -> void:
	if _admob: _admob.showInterstitial()

# Button handlers — Rewarded
func _on_load_rewarded_pressed() -> void:
	if _admob:
		rewarded_status.text = "Rewarded: Loading..."
		_admob.loadRewarded(REWARDED_AD_UNIT_ID)

func _on_show_rewarded_pressed() -> void:
	if _admob: _admob.showRewarded()

# Button handlers — Rewarded Interstitial
func _on_load_rewarded_interstitial_pressed() -> void:
	if _admob:
		rewarded_interstitial_status.text = "Rewarded Interstitial: Loading..."
		_admob.loadRewardedInterstitial(REWARDED_INTERSTITIAL_AD_UNIT_ID)

func _on_show_rewarded_interstitial_pressed() -> void:
	if _admob: _admob.showRewardedInterstitial()

# Button handlers — App Open
func _on_load_app_open_pressed() -> void:
	if _admob:
		app_open_status.text = "App Open: Loading..."
		_admob.loadAppOpen(APP_OPEN_AD_UNIT_ID)

func _on_show_app_open_pressed() -> void:
	if _admob: _admob.showAppOpen()
