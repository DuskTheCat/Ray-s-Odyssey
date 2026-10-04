extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Cast collision_shape.shape to RectangleShape2D so GDScript knows .size exists and is a Vector2
		var rect_shape := collision_shape.shape as RectangleShape2D
		if rect_shape:
			var extents: Vector2 = rect_shape.size / 2.0
			var center: Vector2 = collision_shape.global_position
			
			var left := int(center.x - extents.x)
			var right := int(center.x + extents.x)
			var top := int(center.y - extents.y)
			var bottom := int(center.y + extents.y)
			
			if body.has_method("change_camera_boundaries"):
				body.change_camera_boundaries(left, right, top, bottom)
