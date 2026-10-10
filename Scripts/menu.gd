extends Control

const TEST_LEVEL = "res://Scenes/Tests/TestLevel.tscn"
const TEST_LEVEL_COOP = "res://Scenes/Tests/TestLevelCoop.tscn"
const TEST_SETTINGS = "res://Scenes/Tests/TestSettings.tscn"

@onready var fade: FadeColorRect = $Fade

@export var language: String = "en": 
	set(value):
		language = value
		if Settings.LANGUAGES.has(value):
			TranslationServer.set_locale(value)

func _ready() -> void:
	if Input.get_connected_joypads().size() > 0:
		$VBoxContainer/Button.grab_focus()
	await get_tree().process_frame
	TranslationServer.set_locale(TranslationServer.get_locale())


func _on_button_pressed() -> void:
	_change_scene(TEST_LEVEL)

func _on_button_2_pressed() -> void:
	_change_scene(TEST_LEVEL_COOP)

func _on_button_3_pressed() -> void:
	_change_scene(TEST_SETTINGS)

func _change_scene(scene_path: String) -> void:
	await fade.fade_in()
	LoadingSystem.load_scene(scene_path)
	
func _on_profile_pressed() -> void:
	add_child(ProfileEditor.new())
