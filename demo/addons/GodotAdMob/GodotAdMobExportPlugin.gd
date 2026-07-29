@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name := "GodotAdMob"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray(["GodotAdMob/bin/android/debug/GodotAdMob-debug.aar"])
		return PackedStringArray(["GodotAdMob/bin/android/release/GodotAdMob-release.aar"])

	func _get_name() -> String:
		return _plugin_name

	# Google's public test App ID, so the demo works out of the box.
	# Real consumers must override this with their own AdMob App ID
	# (their export config's manifest merge takes precedence).
	func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		return "<meta-data android:name=\"com.google.android.gms.ads.APPLICATION_ID\" android:value=\"ca-app-pub-3940256099942544~3347511713\"/>"
