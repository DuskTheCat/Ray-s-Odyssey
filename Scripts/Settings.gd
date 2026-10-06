extends Node

const SAVE_PATH = "user://settings.cfg"

# Order here is the order the language button cycles through.
# (Thank you Nya for the suggestion.) -Xansi

## This is a dictionary for languages add any that are missing
## then add their respective translations to translations.
const LANGUAGES: Dictionary[String, String] = {
	"en": "English",
	"ja": "日本語",
	"sv": "Svenska",
}

static func locale_name(code: String) -> String:
	return LANGUAGES.get(code, LANGUAGES["en"])

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
