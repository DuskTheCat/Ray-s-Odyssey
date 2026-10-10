extends PointLight2D

@export var visible_on_screen_notifier2d: VisibleOnScreenNotifier2D

func _ready() -> void:
	assert(visible_on_screen_notifier2d != null, name + " does not have a VisibleOnScreenNotifier2D set.")
	
	visible_on_screen_notifier2d.screen_entered.connect(_on_screen_entered)
	visible_on_screen_notifier2d.screen_exited.connect(_on_screen_exited)
	
	enabled = visible_on_screen_notifier2d.is_on_screen()


func _on_screen_entered() -> void:
	enabled = true

func _on_screen_exited() -> void:
	enabled = false
