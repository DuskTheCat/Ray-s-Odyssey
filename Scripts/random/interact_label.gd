extends Control

@export var text: String = "Interact"

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if not text.is_empty():
		label.text = text
	
	animation_player.play("Show")
	animation_player.advance(0) 
	animation_player.active = false


func show_prompt() -> void:
	animation_player.active = true
	animation_player.stop()
	animation_player.play("Show")

func hide_prompt() -> void:
	animation_player.stop()
	animation_player.play("Hide")
