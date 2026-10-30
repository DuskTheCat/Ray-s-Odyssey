extends MultiplayerSpawner

@export var room_has_checkpoint: bool = false
@export var network_player: PackedScene
@export var second_player: PackedScene
@export var spawn_node: Node2D
@export var is_singleplayer: bool = true

func _ready() -> void:
	spawn_function = _custom_spawn
	
	if is_singleplayer:
		spawn_single_player()
		return
	
	if not multiplayer.is_server(): 
		return
		
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	spawn_host()

func _custom_spawn(data: Dictionary) -> Node:
	var player = network_player.instantiate()
	player.name = str(data["id"])
	
	if data.has("is_from_room"):
		player.is_from_room = data["is_from_room"]
		
	return player

func spawn_host() -> void:
	if multiplayer.is_server():
		spawn_player(1)

func spawn_single_player() -> void:
	var parent_node = get_node_or_null(spawn_path)
	if not parent_node or parent_node.has_node("1"):
		return
	
	var is_from_room: bool = RoomManager.From_A_Room
	print("Spawning singleplayer player with is_from_room: " + str(is_from_room))
	
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
	
	var is_from_room: bool = RoomManager.From_A_Room
	
	print("Spawning multiplayer player " + str(id) + " with is_from_room: " + str(is_from_room))
	
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_singleplayer:
			remove_player(1)
		elif multiplayer.is_server():
			for peer_id in multiplayer.get_peers():
				remove_player(peer_id)
			remove_player(1)
