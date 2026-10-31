extends Node

const save_directory: String = "user://"

const save1: String = save_directory + "save1.save"
const save2: String = save_directory + "save2.save"
const save3: String = save_directory + "save3.save"

signal saving_started
signal game_saved

const default_dictionary: Dictionary = {
	"Room": "res://Scenes/Tests/Test-BottomLeft.tscn",
	"Position": Vector2(81.0, 166.0)
}

func save_game(data: Dictionary, savenumber: int) -> void:
	var save_name: String = _get_save_path(savenumber)
	saving_started.emit()
	
	var save_file: FileAccess = FileAccess.open(save_name, FileAccess.WRITE)
	if save_file == null:
		push_error("Error opening file for writing")
		return
		
	save_file.store_var(data)
	game_saved.emit()
	save_file.close()
	
func load_game(savenumber: int) -> Dictionary:
	var save_name: String = _get_save_path(savenumber)
	
	if FileAccess.file_exists(save_name):
		var save_file: FileAccess = FileAccess.open(save_name, FileAccess.READ)
		if save_file == null:
			push_error("Error reading file")
			return default_dictionary.duplicate(true)
			
		var data = save_file.get_var()
		save_file.close()
		
		if data is Dictionary:
			return data
		else:
			push_error("Corrupted Save Data Type")
	
	return default_dictionary.duplicate(true)
	
func delete_save(savenumber: int) -> void:
	save_game(default_dictionary, savenumber)

func _get_save_path(savenumber: int) -> String:
	match savenumber:
		1: return save1
		2: return save2
		3: return save3
		_:
			assert(false, "Save number not given!! Give either 1, 2, or 3.")
			return save1
