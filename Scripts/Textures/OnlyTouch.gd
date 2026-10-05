extends Control

func _ready() -> void:
	if OS.has_feature("Mobile"):
		visible = true
	else:
		visible = false
