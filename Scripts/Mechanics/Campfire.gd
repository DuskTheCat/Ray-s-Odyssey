extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_label: Control = $InteractLabel
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var point_light_2d: PointLight2D = $PointLight2D

func _ready() -> void:
	# Clear old editor-spawned particles instantly on spawn using built-in methods
	gpu_particles_2d.emitting = false
	gpu_particles_2d.restart()
	
	animation_player.active = false
	point_light_2d.energy = 2.0
	
	# Wait one frame safely using the scene tree's process frame signal
	await get_tree().process_frame
	
	point_light_2d.energy = 0.0
	animation_player.active = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		animation_player.play("Light")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		animation_player.play("PutOut")


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		interact_label.show_prompt()


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		interact_label.hide_prompt()


func _on_interact_area_area_entered(area: Area2D) -> void:
	# Check if the interaction source is valid and particles aren't already running
	if area.is_in_group("Interact"):
		print("Interact")
		(func() -> void:
			var duplicate : GPUParticles2D = gpu_particles_2d.duplicate()
			duplicate.global_position = gpu_particles_2d.global_position
			duplicate.restart()
			get_tree().root.add_child(duplicate)
			await duplicate.finished
			duplicate.queue_free()
		).call_deferred()
