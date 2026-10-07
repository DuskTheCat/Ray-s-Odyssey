## NetworkHandler (Autoload) - hosting and joining over ENet.
## The join box accepts a hex room code, a plain IP, "ip:port", or "local".
## If Tailscale is running, the host uses its Tailscale IP automatically.
extends Node

signal room_code_generated(code: String, ip: String)

const DEFAULT_PORT: int = 42069
const DEFAULT_IP: String = "127.0.0.1"

var peer: ENetMultiplayerPeer
var upnp: UPNP
var active_port: int = 0

func _exit_tree() -> void:
	_cleanup_upnp()

# --- SERVER / HOST ---

func start_server(port: int = DEFAULT_PORT) -> void:
	exit_server()

	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port)
	if error != OK:
		push_error("Failed to start server: %s" % error)
		return

	multiplayer.multiplayer_peer = peer
	active_port = port
	_find_address_and_emit_code(port)

# Priority: 1) Tailscale  2) UPnP public IP  3) LAN IP
func _find_address_and_emit_code(port: int) -> void:
	var ts_ip := get_tailscale_ip()
	if not ts_ip.is_empty():
		room_code_generated.emit(ip_to_code(ts_ip), ts_ip)
		return

	var host_ip := get_local_ip()
	upnp = UPNP.new()
	var discover_result := upnp.discover()

	if discover_result == UPNP.UPNP_RESULT_SUCCESS and upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		var map_udp := upnp.add_port_mapping(port, port, "Godot Game", "UDP")
		if map_udp != UPNP.UPNP_RESULT_SUCCESS:
			map_udp = upnp.add_port_mapping(port, port, "", "UDP")
		if map_udp != UPNP.UPNP_RESULT_SUCCESS:
			push_warning("UPnP UDP Port Mapping failed with error code: %d" % map_udp)

		var external_ip := upnp.query_external_address()
		if not external_ip.is_empty():
			host_ip = external_ip
	else:
		push_warning("UPnP Discovery failed (Error: %d). Using Local IP fallback: %s" % [discover_result, host_ip])

	room_code_generated.emit(ip_to_code(host_ip), host_ip)

func exit_server() -> void:
	_cleanup_upnp()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	peer = null

func _cleanup_upnp() -> void:
	if upnp and active_port > 0:
		upnp.delete_port_mapping(active_port, "UDP")
		upnp = null
		active_port = 0

# --- CLIENT ---

func start_client(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> void:
	exit_server()

	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, port)
	if error != OK:
		push_error("Failed to connect to server: %s" % error)
		return

	multiplayer.multiplayer_peer = peer

func join_via_room_code(code: String, default_port: int = DEFAULT_PORT) -> void:
	var clean_code := code.strip_edges()
	var port := default_port

	if clean_code.contains(":"):
		var bits := clean_code.split(":")
		clean_code = bits[0].strip_edges()
		if bits.size() > 1 and bits[1].strip_edges().is_valid_int():
			port = bits[1].strip_edges().to_int()

	if clean_code.to_lower() == "local":
		start_client(DEFAULT_IP, port)
		return

	if clean_code.is_valid_ip_address():
		start_client(clean_code, port)
		return

	var target_ip := code_to_ip(clean_code)
	if target_ip.is_empty():
		push_warning("Join failed: enter an 8-character room code or an IP address.")
		return

	start_client(target_ip, port)

# --- NETWORK DISCOVERY ---

func get_tailscale_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("100."):
			var second := ip.split(".")[1].to_int()
			if second >= 64 and second <= 127:
				return ip
	return ""

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or (ip.begins_with("172.") and ip.split(".")[1].to_int() >= 16 and ip.split(".")[1].to_int() <= 31):
			return ip
	return DEFAULT_IP

# --- ROOM CODE ENCODER / DECODER ---

func ip_to_code(ip: String) -> String:
	var parts := ip.split(".")
	if parts.size() != 4:
		return ""
	var hex_code := ""
	for part in parts:
		hex_code += "%02X" % part.to_int()
	return hex_code

func code_to_ip(code: String) -> String:
	var clean_code := code.strip_edges().to_upper()
	if clean_code.length() != 8 or not clean_code.is_valid_hex_number():
		return ""
	var ip_parts: Array[String] = []
	for i in range(0, 8, 2):
		ip_parts.append(str(clean_code.substr(i, 2).hex_to_int()))
	return ".".join(ip_parts)
