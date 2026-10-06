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
	animation_player.seek(0.0, true)
	animation_player.play("Fade_In")
	await animation_player.animation_finished
	fade_finished.emit()

func fade_out() -> void:
	if animation_player.current_animation_position == 0.0:
		var anim_length = animation_player.get_animation("Fade_In").length
		animation_player.seek(anim_length, true)
		
	animation_player.play_backwards("Fade_In")
	await animation_player.animation_finished
	fade_finished.emit()
