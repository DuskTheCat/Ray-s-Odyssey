extends Area2D

func _ready() -> void:
	body_entered.connect(entered)

func entered() -> void:
	pass
