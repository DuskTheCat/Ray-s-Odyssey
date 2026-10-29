extends Node

const save_directory: String = "user://"

const save1: String = save_directory + "save1.json"
const save2: String = save_directory + "save2.json"
const save3: String = save_directory + "save3.json"

const default_dictionary: Dictionary = {
	"Room": "res://Scenes/Tests/Test-BottomLeft.tscn"
}

func save_game(data: Dictionary, savenumber: int) -> void:
	
	var save_name: String
	
	if savenumber == 1:
		save_name = save1
	elif savenumber == 2:
		save_name = save2
	elif savenumber == 3:
		save_name = save3
	
	if not save_name:
		assert(false, "Save number not given!! Give either 1, 2, or 3.")
	
	var save_file: FileAccess = FileAccess.open(save_name, FileAccess.WRITE)
	if save_file == null:
		push_error("Error opening file")
		return
	var string_data: String = JSON.stringify(data)
	save_file.store_line(string_data)
	save_file.close()
	
func load_game(savenumber: int) -> Dictionary:
	var save_name: String
	
	if savenumber == 1:
		save_name = save1
	elif savenumber == 2:
		save_name = save2
	elif savenumber == 3:
		save_name = save3
	
	if not save_name:
		assert(false, "Save number not given!! Give either 1, 2, or 3.")
	
	if FileAccess.file_exists(save_name):
		var save_file: FileAccess = FileAccess.open(save_name, FileAccess.READ)
		if save_file == null:
			push_error("Error reading file")
			return default_dictionary
		var json = JSON.new()
		
		var string_data: String = save_file.get_line()
		if json.parse(string_data) == OK:
			
			var data: Dictionary = json.data
			save_file.close()
			return data
		
		push_error("Corrupted Save")
	return default_dictionary
	
func delete_save(savenumber: int) -> void:
	save_game(default_dictionary, savenumber)
