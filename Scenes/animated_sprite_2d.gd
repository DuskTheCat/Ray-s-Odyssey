extends AnimatedSprite2D

@export var Anim : String

func _ready() -> void:
	play(Anim)
