extends Control

const MAIN_MENU = "res://Scenes/Menus/menu.tscn"

@onready var language_button: Button = $LanguageButton

func _ready() -> void:
	language_button.pressed.connect(_on_language_button_pressed)
	_update_button_text()

func _on_language_button_pressed() -> void:
	var codes: Array = Settings.LANGUAGES.keys()
	var current: int = codes.find(TranslationServer.get_locale().substr(0, 2))
	var next: int = (current + 1) % codes.size()
	TranslationServer.set_locale(codes[next])
	Settings.save_locale()
	_update_button_text()

func _update_button_text() -> void:
	var code: String = TranslationServer.get_locale().substr(0, 2)
	language_button.text = Settings.LANGUAGES.get(code, Settings.LANGUAGES["en"])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Settings.save_locale()
		get_tree().change_scene_to_file(MAIN_MENU)
