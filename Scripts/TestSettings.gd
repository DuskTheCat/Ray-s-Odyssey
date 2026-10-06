extends Control

const MAIN_MENU = "res://Scenes/Menus/menu.tscn"

@onready var language_button: Button = $LanguageButton
@onready var fade: FadeColorRect = $Fade

var _is_changing_scene: bool = false

func _ready() -> void:
	language_button.pressed.connect(_on_language_button_pressed)
	_update_button_text()

func _on_language_button_pressed() -> void:
	var codes: Array = Settings.LANGUAGES
	# Extract 2-letter base code (e.g., "en_US" -> "en") to safely match Settings.LANGUAGES
	var current_locale: String = TranslationServer.get_locale().left(2)
	var current: int = Settings.get_locale_index(current_locale)
	
	# Fallback if locale wasn't found in array
	if current == -1:
		current = 0
		
	var next: int = (current + 1) % codes.size()
	TranslationServer.set_locale(codes[next])
	Settings.save_locale()
	_update_button_text()

func _update_button_text() -> void:
	var code: String = TranslationServer.get_locale().left(2)
	language_button.text = Settings.get_locale_name(code)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _is_changing_scene:
		_is_changing_scene = true
		get_viewport().set_input_as_handled()
		
		Settings.save_locale()
		await fade.fade_in()
		LoadingSystem.load_scene(MAIN_MENU)
