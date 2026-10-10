## NameTag - drop-in component. Add as a child of ANY character (Node2D) and it
## shows that player's profile picture + name above their head.
## It figures out who it belongs to from the parent's multiplayer authority,
## so it works for anything spawned the same way as your player.
class_name NameTag
extends Node2D

@export var offset: Vector2 = Vector2(0, -40)   # where the tag sits relative to the parent
@export var avatar_size: float = 20.0
@export var font_size: int = 12
@export var font: Font                          # optional custom font
@export var avatar_left: bool = true            # false = name first, picture after
@export var hide_on_local_player: bool = false  # true = you don't see your own tag
## Draws the tag this many times bigger, then shrinks it back down. Keeps text
## crisp when the camera is zoomed in. Raise it if still blurry (3-6 is plenty).
@export_range(1, 8) var sharpness: int = 4

var _peer_id: int = 1
var _box: HBoxContainer
var _icon: TextureRect
var _label: Label

func _ready() -> void:
	z_index = 100
	position = offset
	scale = Vector2.ONE / float(sharpness)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build()
	_peer_id = get_parent().get_multiplayer_authority()
	if hide_on_local_player and _peer_id == multiplayer.get_unique_id():
		visible = false
		return
	PlayerProfile.profiles_changed.connect(_refresh)
	_refresh()

func _build() -> void:
	_box = HBoxContainer.new()
	_box.add_theme_constant_override("separation", 4 * sharpness)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(avatar_size, avatar_size) * sharpness
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", font_size * sharpness)
	_label.add_theme_constant_override("outline_size", 4 * sharpness)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font:
		_label.add_theme_font_override("font", font)

	if avatar_left:
		_box.add_child(_icon)
		_box.add_child(_label)
	else:
		_box.add_child(_label)
		_box.add_child(_icon)

func _refresh() -> void:
	_label.text = PlayerProfile.get_display_name(_peer_id)
	_icon.texture = PlayerProfile.get_avatar_texture(_peer_id)
	# Center the tag horizontally, sitting just above the anchor point
	var s := _box.get_combined_minimum_size()
	_box.size = s
	_box.position = Vector2(-s.x / 2.0, -s.y)
