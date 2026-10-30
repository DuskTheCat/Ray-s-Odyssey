extends MultiplayerSpawner

@export var room_has_checkpoint: bool = false
@export var network_player: PackedScene
@export var second_player: PackedScene
@export var spawn_node: Node2D # Converted to snake_case for GDScript conventions
@export var is_singleplayer: bool = true

func _ready() -> void:
	# Set Godot's custom spawn function for this spawner
	spawn_function = _custom_spawn
	
	if is_singleplayer:
		spawn_single_player()
		return
	
	if not multiplayer.is_server(): 
		return
		
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# Spawn the host (peer 1) automatically when the scene starts!
	spawn_host()

# Custom spawn method used internally by Godot's MultiplayerSpawner (and singleplayer)
func _custom_spawn(data: Dictionary) -> Node:
	var player = network_player.instantiate()
	player.name = str(data["id"])
	
	# Set the is_from_room property on the player instance using the replicated data
	if data.has("is_from_room"):
		player.is_from_room = data["is_from_room"]
		
	return player

# Public function to trigger host spawn manually
func spawn_host() -> void:
	if multiplayer.is_server():
		spawn_player(1)

# Spawns the player locally for singleplayer mode
func spawn_single_player() -> void:
	var parent_node = get_node_or_null(spawn_path)
	if not parent_node or parent_node.has_node("1"):
		return
	
	var is_from_room: bool = RoomManager.From_A_Room
	print("Spawning singleplayer player with is_from_room: " + str(is_from_room))
	
	# Directly instantiate and add to the scene tree in singleplayer mode
	var player = _custom_spawn({
		"id": 1,
		"is_from_room": is_from_room
	})
	parent_node.add_child(player)

func spawn_player(id: int) -> void:
	if not multiplayer.is_server(): 
		return
	
	var parent_node = get_node_or_null(spawn_path)
	if not parent_node or parent_node.has_node(str(id)):
		return
	
	# Determine the boolean value from RoomManager
	var is_from_room: bool = RoomManager.From_A_Room
	
	print("Spawning multiplayer player " + str(id) + " with is_from_room: " + str(is_from_room))
	
	# Trigger the spawn across all peers, passing both the ID and is_from_room state in the data dictionary
	spawn({
		"id": id,
		"is_from_room": is_from_room
	})

func remove_player(id: int) -> void:
	if not multiplayer.is_server() and not is_singleplayer: 
		return
		
	var parent_node = get_node_or_null(spawn_path)
	if parent_node and parent_node.has_node(str(id)):
		var player_node = parent_node.get_node(str(id))
		player_node.queue_free()

# Handle local quit gracefully for the host, local peer, or singleplayer
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_singleplayer:
			remove_player(1)
		elif multiplayer.is_server():
			for peer_id in multiplayer.get_peers():
				remove_player(peer_id)
			remove_player(1) # Remove host
