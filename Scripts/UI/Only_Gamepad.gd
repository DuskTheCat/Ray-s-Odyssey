extends Control

const JOY_DEADZONE: float = 0.2

func _ready() -> void:
	visible = Input.get_connected_joypads().size() > 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseMotion:
		if visible:
			hide()
			
	elif event is InputEventJoypadButton:
		if not visible:
			show()
			
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > JOY_DEADZONE:
			if not visible:
				show()
