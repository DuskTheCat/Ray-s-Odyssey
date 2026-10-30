extends Area2D

enum Direction {Left, Down, Up, Right}
@export var Room: PackedScene
@export var Enter_Direction: Direction

func _ready() -> void:
	body_entered.connect(entered)

func entered() -> void:
	pass
