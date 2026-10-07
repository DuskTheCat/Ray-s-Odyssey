extends Label

func _ready() -> void:
	_apply(Settings.show_fps)
	Settings.show_fps_changed.connect(_apply)

func _apply(enabled: bool) -> void:
	visible = enabled
	set_process(enabled)

func _process(_delta: float) -> void:
	text = str(Performance.get_monitor(Performance.TIME_FPS))
