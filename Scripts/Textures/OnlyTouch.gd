extends Control

func _enter_tree() -> void:
	visible = OS.has_feature("mobile")
	print("Is mobile!") if OS.has_feature("mobile") else print("NotMobile :<")
