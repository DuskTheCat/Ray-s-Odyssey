extends Node

signal show_fps_changed(enabled: bool)

const SAVE_PATH = "user://settings.cfg"

# Order here is the order the language button cycles through.
# (Thank you Nya for the suggestion.) -Xansi

## Set of all available languages that may be selected
const LANGUAGES: Array[String] = ["en", "ja", "sv", "fr"]

## This is a dictionary for resolving  language names; Add any that are missing,
## then add their respective translations to the CSV.[br]
## When seeking the name of a language, prefer using [method get_locale_name].
## This may be removed in the future.
## @experimental
const _LANGUAGE_NAMES: Dictionary[String, String] = {
	"en": "English",
	"ja": "日本語",
	"sv": "Svenska",
	"fr": "Français"
}

## A safe default language that can be used as a fallback
const DEFAULT_LANGUAGE: String = "en"

## FPS cap applied when VSync is off, so the GPU isn't maxed out. 0 = uncapped.
const FPS_CAP_NO_VSYNC: int = 144

## Whether vertical sync is on. Change it through [method set_vsync].
var vsync_enabled: bool = true

## Whether the FPS counter is visible. Change it through [method set_show_fps].
var show_fps: bool = false

## Returns the most appropriate human-readable name of a language, specified by 
## its code.
## Accepts locale+region formats (en_US) and will fallback to just locale (en)
## if the specific region is not available.
static func get_locale_name(code: String, default_name: String = "Unknown") -> String:
	# TODO: Resolve through CSV. The same language can have different names in
	# other languages; The French would call English "Anglais", for instance.
	
	var result = _LANGUAGE_NAMES.get(code, null)
	if result == null:
		result = _LANGUAGE_NAMES.get(code.substr(0, 2), default_name)
	return result

## Gets the index of a locale within the [member LANGUAGES] array.
## Accepts locale+region formats (en_US) and will fallback to just locale (en)
## if the specific region is not available.
static func get_locale_index(code: String, default_index: int = 0) -> int:
	var result = LANGUAGES.find(code)
	if result == -1:
		result = LANGUAGES.find(code.substr(0, 2))
		
	return result if result > -1 else default_index

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		vsync_enabled = config.get_value("video", "vsync", true)
		show_fps = config.get_value("video", "show_fps", false)
		apply_vsync()
		var saved: String = config.get_value("general", "locale", "en")
		TranslationServer.set_locale(saved)
		# Re-apply after the first scene has loaded so the UI refreshes.
		await get_tree().process_frame
		TranslationServer.set_locale(saved)
	print("Settings loaded, locale: ", TranslationServer.get_locale())

func save_locale() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("general", "locale", TranslationServer.get_locale())
	config.save(SAVE_PATH)

## Turns VSync on or off, applies it immediately, and saves the choice.
func set_vsync(enabled: bool) -> void:
	vsync_enabled = enabled
	apply_vsync()
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("video", "vsync", vsync_enabled)
	config.save(SAVE_PATH)

## Applies the current VSync setting to the window.
func apply_vsync() -> void:
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Engine.max_fps = 0 # VSync already limits it
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = FPS_CAP_NO_VSYNC

## Shows or hides the FPS counter and saves the choice.
func set_show_fps(enabled: bool) -> void:
	show_fps = enabled
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("video", "show_fps", show_fps)
	config.save(SAVE_PATH)
	show_fps_changed.emit(show_fps)
