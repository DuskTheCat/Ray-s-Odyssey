## NetworkUI - the Host / Join menu.
## HOST: press Host, send your friend the Code or IP shown.
## JOIN: paste the host's room code or IP into the box and press Join.
extends Control

@onready var multiplayer_spawner: MultiplayerSpawner = $"../../MultiplayerSpawner"
@onready var server_code: Label = $ServerCode
@onready var input_code: LineEdit = $VBoxContainer2/InputCode

func _ready() -> void:
	# Host-only event: room code / IP are ready
	NetworkHandler.room_code_generated.connect(_on_room_code_generated)

	# Client events
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_host_pressed() -> void:
	server_code.text = "Generating code..."
	NetworkHandler.start_server()

func _on_join_pressed() -> void:
	if not is_instance_valid(input_code):
		push_error("input_code node reference is missing or invalid!")
		return

	var code = input_code.text.strip_edges()

	if code.is_empty():
		push_warning("Join attempted with empty code.")
		server_code.text = "Enter a room code or IP first."
		return

	server_code.text = "Connecting to host..."
	NetworkHandler.join_via_room_code(code)

# --- HOST CALLBACK ---
func _on_room_code_generated(code: String, ip: String) -> void:
	if multiplayer.is_server():
		server_code.text = "Code: %s  |  IP: %s" % [code, ip]
		multiplayer_spawner.spawn_host()

# --- CLIENT CALLBACKS ---
func _on_connected_to_server() -> void:
	server_code.text = "Connected!"
	print("Successfully connected to host!")

func _on_connection_failed() -> void:
	server_code.text = "Connection failed! Check the code/IP, and make sure you're both on Tailscale."
	push_error("Could not connect to host server.")

func _on_input_code_focus_entered() -> void:
	DisplayServer.virtual_keyboard_show(input_code.text)
