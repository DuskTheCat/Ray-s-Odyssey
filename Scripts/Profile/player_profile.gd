## PlayerProfile
## Stores your name & profile picture (saved to disk) and keeps a registry of
## everyone else's name + picture, synced through the host.
## Anything that wants a name/picture just asks:
##     PlayerProfile.get_display_name(peer_id)
##     PlayerProfile.get_avatar_texture(peer_id)
## and listens to `profiles_changed` to refresh.
extends Node

signal profiles_changed

const AVATAR_SIZE := 64             # pictures are shrunk to 64x64 so they're tiny to send
const MAX_NAME_LENGTH := 16
const MAX_AVATAR_BYTES := 32768     # host rejects anything bigger than this
const DEFAULT_NAME := "Player"
const SAVE_PATH := "user://profile.cfg"
const AVATAR_PATH := "user://avatar.png"

var local_name: String = DEFAULT_NAME
var local_avatar: Image = null      # already cropped/circled/resized, or null

var _remote: Dictionary = {}        # peer_id -> {"name": String, "png": PackedByteArray}
var _texture_cache: Dictionary = {} # peer_id -> ImageTexture
var _local_texture: ImageTexture = null
var _default_texture: ImageTexture = null

func _ready() -> void:
	_load_local()
	_default_texture = ImageTexture.create_from_image(_make_default_avatar())
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(reset)

# --- PUBLIC API ---

func get_display_name(id: int) -> String:
	if id == multiplayer.get_unique_id():
		return local_name
	if _remote.has(id):
		return _remote[id]["name"]
	return "Player %d" % id # profile hasn't arrived yet

func get_avatar_texture(id: int) -> Texture2D:
	if id == multiplayer.get_unique_id():
		if _local_texture == null and local_avatar != null:
			_local_texture = ImageTexture.create_from_image(local_avatar)
		return _local_texture if _local_texture else _default_texture
	if _texture_cache.has(id):
		return _texture_cache[id]
	if _remote.has(id) and not _remote[id]["png"].is_empty():
		var img := Image.new()
		if img.load_png_from_buffer(_remote[id]["png"]) == OK:
			var tex := ImageTexture.create_from_image(img)
			_texture_cache[id] = tex
			return tex
	return _default_texture

## Everyone currently known, including you.
func get_all_ids() -> Array[int]:
	var ids: Array[int] = []
	for k in _remote.keys():
		ids.append(int(k))
	var me := multiplayer.get_unique_id()
	if not ids.has(me):
		ids.append(me)
	ids.sort()
	return ids

## Called by the profile editor. Saves to disk and syncs if you're online.
func set_local_profile(new_name: String, avatar: Image) -> void:
	local_name = _clean_name(new_name)
	if avatar != null:
		local_avatar = avatar
		_local_texture = null
	_save_local()
	_push_local()
	profiles_changed.emit()

## Turns any image from disk into a 64x64 circular avatar. Returns null on failure.
func make_avatar_from_file(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	return _make_avatar(img)

## Forget everyone else (call when leaving a game).
func reset() -> void:
	_remote.clear()
	_texture_cache.clear()
	profiles_changed.emit()

# --- NETWORKING ---

func _is_online() -> bool:
	var p := multiplayer.multiplayer_peer
	return p != null and not (p is OfflineMultiplayerPeer) \
		and p.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func _push_local() -> void:
	if not _is_online():
		return
	if multiplayer.is_server():
		_receive_profile.rpc(1, local_name, _local_png())
	else:
		_submit_profile.rpc_id(1, local_name, _local_png())

func _on_connected_to_server() -> void:
	_remote.clear()
	_texture_cache.clear()
	_push_local()
	profiles_changed.emit()

# Host: a new peer joined -> give them the host's profile + everyone already here.
func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	_receive_profile.rpc_id(id, 1, local_name, _local_png())
	for pid in _remote.keys():
		_receive_profile.rpc_id(id, pid, _remote[pid]["name"], _remote[pid]["png"])

func _on_peer_disconnected(id: int) -> void:
	_remote.erase(id)
	_texture_cache.erase(id)
	profiles_changed.emit()

# Client -> host: "here's my profile"
@rpc("any_peer", "reliable")
func _submit_profile(display_name: String, png: PackedByteArray) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	_store(id, display_name, png)
	# Host tells everyone (the sender ignores their own entry)
	_receive_profile.rpc(id, _remote[id]["name"], _remote[id]["png"])

# Host -> clients: "this is peer X's profile"
@rpc("authority", "reliable")
func _receive_profile(id: int, display_name: String, png: PackedByteArray) -> void:
	if multiplayer.get_remote_sender_id() != 1 or id == multiplayer.get_unique_id():
		return
	_store(id, display_name, png)

func _store(id: int, display_name: String, png: PackedByteArray) -> void:
	if png.size() > MAX_AVATAR_BYTES:
		png = PackedByteArray()
	_remote[id] = {"name": _clean_name(display_name), "png": png}
	_texture_cache.erase(id)
	profiles_changed.emit()

# --- IMAGE / SAVE HELPERS ---

func _local_png() -> PackedByteArray:
	return local_avatar.save_png_to_buffer() if local_avatar != null else PackedByteArray()

func _clean_name(raw: String) -> String:
	var n := raw.strip_edges().substr(0, MAX_NAME_LENGTH)
	return n if not n.is_empty() else DEFAULT_NAME

func _make_avatar(img: Image) -> Image:
	img.convert(Image.FORMAT_RGBA8)
	var side := mini(img.get_width(), img.get_height())
	var square := img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
	square.resize(AVATAR_SIZE, AVATAR_SIZE, Image.INTERPOLATE_LANCZOS)
	_apply_circle_mask(square)
	return square

func _apply_circle_mask(img: Image) -> void:
	var center := Vector2(AVATAR_SIZE - 1, AVATAR_SIZE - 1) / 2.0
	var radius := AVATAR_SIZE / 2.0
	for y in AVATAR_SIZE:
		for x in AVATAR_SIZE:
			var c := img.get_pixel(x, y)
			c.a *= clampf(radius - Vector2(x, y).distance_to(center) + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, c)

func _make_default_avatar() -> Image:
	var img := Image.create(AVATAR_SIZE, AVATAR_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.45, 0.5, 0.6))
	_apply_circle_mask(img)
	return img

func _save_local() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "name", local_name)
	cfg.save(SAVE_PATH)
	if local_avatar != null:
		local_avatar.save_png(AVATAR_PATH)

func _load_local() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		local_name = _clean_name(str(cfg.get_value("profile", "name", DEFAULT_NAME)))
	if FileAccess.file_exists(AVATAR_PATH):
		var img := Image.load_from_file(AVATAR_PATH)
		if img != null and not img.is_empty():
			local_avatar = img
