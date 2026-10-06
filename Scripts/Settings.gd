extends Node

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
