extends Node

signal loading_progress(progress_amount: float)
signal scene_loaded

const loading_screen_scene: PackedScene = preload("uid://taroyrf6qcy5")

# Minimum time (in seconds) the loading screen remains visible
const MIN_LOAD_TIME: float = 0.6 

var new_loading_screen: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func load_scene(scene_to_load: String) -> void:
	get_tree().paused = true
	
	new_loading_screen = loading_screen_scene.instantiate()
	new_loading_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(new_loading_screen)
	
	# Optional: Trigger fade-in on the loading screen if implemented
	if new_loading_screen.has_method("fade_in"):
		await new_loading_screen.fade_in()
	
	# Render 1 frame so the loading screen appears before blocking the main thread
	await get_tree().process_frame
	
	var start_time: float = Time.get_ticks_msec() / 1000.0
	
	# 1. Load and swap scenes while paused
	var loaded_packed_scene: PackedScene = ResourceLoader.load(scene_to_load)
	var new_scene_instance: Node = loaded_packed_scene.instantiate()
	
	var old_scene: Node = get_tree().current_scene
	get_tree().root.add_child(new_scene_instance)
	get_tree().current_scene = new_scene_instance
	
	if is_instance_valid(old_scene):
		old_scene.queue_free()
		
	# 2. Wait for physics shapes to register in PhysicsServer3D while STILL PAUSED.
	# Pausing prevents gravity from pulling dynamic bodies through unregistered static colliders.
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# 3. Enforce minimum display time so small scenes don't flash instantly
	var elapsed_time: float = (Time.get_ticks_msec() / 1000.0) - start_time
	if elapsed_time < MIN_LOAD_TIME:
		var remaining_time: float = MIN_LOAD_TIME - elapsed_time
		# process_always=true allows this timer to run while the SceneTree is paused
		await get_tree().create_timer(remaining_time, true, false, true).timeout
	
	# 4. Fade out loading screen if available, then remove overlay
	if is_instance_valid(new_loading_screen) and new_loading_screen.has_method("fade_out"):
		await new_loading_screen.fade_out()
		
	
	
	await get_tree().create_timer(1).timeout
	emit_signal("scene_loaded")
	# 5. Unpause ONLY after floor colliders are registered and overlay is cleared
	get_tree().paused = false
