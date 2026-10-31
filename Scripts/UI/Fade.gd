extends ColorRect
class_name FadeColorRect

signal fade_finished

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = true
	fade_out()

# Inside FadeColorRect.gd
func fade_in() -> void:
	show()
	animation_player.stop()
	animation_player.play("Fade_In")
	await animation_player.animation_finished
	fade_finished.emit()

func fade_out() -> void:
	
	animation_player.stop(false)
	animation_player.play_backwards("Fade_In")
	await animation_player.animation_finished
	fade_finished.emit()
