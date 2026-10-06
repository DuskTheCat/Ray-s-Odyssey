extends CanvasLayer

@onready var progress_bar: ProgressBar = $Everything/ProgressBar
@onready var compile_parent: Node2D = $Everything/CompileParent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	LoadingSystem.scene_loaded.connect(loading_complete)
	
func update_load_progress(progress: float) -> void:
	progress_bar.value = progress * 100.0
	
func loading_complete() -> void:
	progress_bar.value = progress_bar.max_value
	animation_player.play("Fade_out")
	animation_player.animation_finished.connect(func() -> void:
		queue_free()
		)
