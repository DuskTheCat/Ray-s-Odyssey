extends Node

signal precompile_finished

## Array of 2D PackedScenes (.tscn) containing shaders
@export var scenes_to_precompile: Array[PackedScene] = []
const MAIN_SCENE : String = "res://Scenes/Menus/menu.tscn"

## Array of standalone 2D CanvasItem materials (.tres / ShaderMaterial)
@export var materials_2d_to_precompile: Array[Material] = []

@onready var container_2d: Node2D = $SubViewportContainer/SubViewport/Container2D

func _ready() -> void:
	start_precompilation()

func start_precompilation() -> void:
	# 1. Instantiate all 2D PackedScenes inside the viewport
	for scene in scenes_to_precompile:
		if scene:
			var instance = scene.instantiate()
			container_2d.add_child(instance)

	# 2. Attach standalone 2D materials to dummy ColorRect nodes
	for mat in materials_2d_to_precompile:
		if mat:
			var rect = ColorRect.new()
			rect.size = Vector2(64, 64)
			rect.material = mat
			container_2d.add_child(rect)

	# 3. Wait 2 frames for Godot's RenderingServer to build the CanvasItem shaders
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	# 4. Clean up temporary nodes
	for child in container_2d.get_children():
		child.queue_free()

	# 5. Signal completion
	precompile_finished.emit()
	
	LoadingSystem.load_scene(MAIN_SCENE)
