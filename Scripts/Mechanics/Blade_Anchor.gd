extends Node2D

@onready var mouse_area: Area2D = $MouseArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var lock_on: Sprite2D = $LockOn

func _ready() -> void:
	mouse_area.mouse_entered.connect(lockon)
	mouse_area.mouse_exited.connect(lockout)

func lockon() -> void:
	animation_player.stop()
	animation_player.play("Lock_On")

func lockout() -> void:
	animation_player.stop()
	animation_player.play("Lock_Out")
