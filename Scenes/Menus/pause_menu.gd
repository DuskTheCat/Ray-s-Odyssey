extends CanvasLayer

const MAIN_MENU = "res://Scenes/Menus/menu.tscn"

@onready var resume_button: Button = $MarginContainer/VBoxContainer/Resume
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Quit
@onready var fade: FadeColorRect = $Fade

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		set_paused(not visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		set_paused(false)
		get_viewport().set_input_as_handled()

func is_online() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and not peer is OfflineMultiplayerPeer

func set_paused(value: bool) -> void:
	visible = value
	if not is_online():
		get_tree().paused = value
		if Input.get_connected_joypads().size() > 0:
			$MarginContainer/VBoxContainer/Resume.grab_focus()

func _on_resume_pressed() -> void:
	set_paused(false)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	await fade.fade_in()
	LoadingSystem.load_scene(MAIN_MENU)
