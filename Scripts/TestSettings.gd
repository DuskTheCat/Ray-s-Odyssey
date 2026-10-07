extends Control

const MAIN_MENU = "res://Scenes/Menus/menu.tscn"

@onready var language_button: Button = $LanguageButton
@onready var vsync_button: Button = $VSyncButton
@onready var fps_button: Button = $FPSButton
@onready var fade: FadeColorRect = $Fade

var _is_changing_scene: bool = false

func _ready() -> void:
	language_button.pressed.connect(_on_language_button_pressed)
	vsync_button.pressed.connect(_on_vsync_button_pressed)
	fps_button.pressed.connect(_on_fps_button_pressed)
	_update_button_text()
	if Input.get_connected_joypads().size() > 0:
		$LanguageButton.grab_focus()

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

func _on_vsync_button_pressed() -> void:
	Settings.set_vsync(not Settings.vsync_enabled)
	_update_button_text()

func _on_fps_button_pressed() -> void:
	Settings.set_show_fps(not Settings.show_fps)
	_update_button_text()

# Button text will get updated per settings based on these translatable strings.
func _update_button_text() -> void:
	var code: String = TranslationServer.get_locale().left(2)
	language_button.text = Settings.get_locale_name(code)
	
	var vsync_state: String = tr("SETTINGS_ON") if Settings.vsync_enabled else tr("SETTINGS_OFF")
	var fps_state: String = tr("SETTINGS_ON") if Settings.show_fps else tr("SETTINGS_OFF")
	vsync_button.text = tr("SETTINGS_VSYNC") + ": " + vsync_state
	fps_button.text = tr("SETTINGS_SHOW_FPS") + ": " + fps_state

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _is_changing_scene:
		_is_changing_scene = true
		get_viewport().set_input_as_handled()
		
		Settings.save_locale()
		await fade.fade_in()
		LoadingSystem.load_scene(MAIN_MENU)
