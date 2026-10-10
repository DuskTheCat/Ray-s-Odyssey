## ProfileEditor popup where the player picks a name & profile picture.
##     add_child(ProfileEditor.new()) to use it example in menu.gd
class_name ProfileEditor
extends Control

var _avatar: Image = null
var _preview: TextureRect
var _name_edit: LineEdit
var _status: Label
var _dialog: FileDialog

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Your Profile"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(96, 96)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_preview.texture = PlayerProfile.get_avatar_texture(multiplayer.get_unique_id())
	box.add_child(_preview)

	var pick := Button.new()
	pick.text = "Choose Picture..."
	pick.pressed.connect(func(): _dialog.popup_centered_ratio(0.7))
	box.add_child(pick)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	_name_edit.text = PlayerProfile.local_name
	_name_edit.max_length = PlayerProfile.MAX_NAME_LENGTH
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.custom_minimum_size.x = 260
	box.add_child(_name_edit)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	var save := Button.new()
	save.text = "Save"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.pressed.connect(_on_save)
	buttons.add_child(save)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(queue_free)
	buttons.add_child(cancel)

	_dialog = FileDialog.new()
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.use_native_dialog = true
	_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"])
	_dialog.file_selected.connect(_on_file_selected)
	add_child(_dialog)

func _on_file_selected(path: String) -> void:
	var img := PlayerProfile.make_avatar_from_file(path)
	if img == null:
		_status.text = "Couldn't load that image."
		return
	_status.text = ""
	_avatar = img
	_preview.texture = ImageTexture.create_from_image(img)

func _on_save() -> void:
	PlayerProfile.set_local_profile(_name_edit.text, _avatar)
	queue_free()
