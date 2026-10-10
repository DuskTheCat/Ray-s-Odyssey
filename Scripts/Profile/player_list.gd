## PlayerList shows who's playing. Drop it into any UI
## (lobby screen, pause menu, corner of the HUD). Updates itself (may be bugged on mobile!).
class_name PlayerList
extends VBoxContainer

@export var avatar_size: float = 32.0
@export var font_size: int = 20

func _ready() -> void:
	PlayerProfile.profiles_changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var me := multiplayer.get_unique_id()
	for id in PlayerProfile.get_all_ids():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(avatar_size, avatar_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = PlayerProfile.get_avatar_texture(id)
		row.add_child(icon)

		var label := Label.new()
		var text := PlayerProfile.get_display_name(id)
		if id == 1:
			text += " (host)"
		if id == me:
			text += " (you)"
		label.text = text
		label.add_theme_font_size_override("font_size", font_size)
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(label)

		add_child(row)
