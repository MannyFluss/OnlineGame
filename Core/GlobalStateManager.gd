extends Node

const SAVE_PATH = "user://saves/"
const SAVE_FILE = "save_slot_1.json"

signal runtime_changed(key: String, value: Variant)
signal persistent_changed(key: String, value: Variant)

var _persistent_data: Dictionary = {}
var _runtime_state: Dictionary = {}

func _ready() -> void:
	_initialize_data_structure()
	load_game()

func _initialize_data_structure() -> void:
	_persistent_data = {}
	_runtime_state = {}

func set_runtime(key: String, value: Variant) -> void:
	_runtime_state[key] = value
	var value_copy = value
	if value is Dictionary or value is Array:
		value_copy = value.duplicate(true)
	runtime_changed.emit(key, value_copy)

func get_runtime(key: String, default = null) -> Variant:
	return _runtime_state.get(key, default)

func set_persistent(key: String, value: Variant) -> void:
	_persistent_data[key] = value
	var value_copy = value
	if value is Dictionary or value is Array:
		value_copy = value.duplicate(true)
	persistent_changed.emit(key, value_copy)

func get_persistent(key: String, default = null) -> Variant:
	return _persistent_data.get(key, default)

func save_game() -> bool:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_absolute(SAVE_PATH)

	var json_string = JSON.stringify(_persistent_data)
	var file = FileAccess.open(SAVE_PATH + SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save game: could not open file")
		return false

	file.store_string(json_string)
	print("Game saved successfully to: ", SAVE_PATH + SAVE_FILE)
	return true

func load_game() -> bool:
	var file_path = SAVE_PATH + SAVE_FILE

	if not ResourceLoader.exists(file_path):
		print("No save file found. Using default data.")
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to load game: could not open file")
		return false

	var json = JSON.new()
	var json_string = file.get_as_text()
	var error = json.parse(json_string)

	if error != OK:
		push_error("Failed to parse save file: ", json.get_error_message())
		return false

	var loaded_data = json.get_data()
	if loaded_data is Dictionary:
		_persistent_data = loaded_data
		print("Game loaded successfully from: ", file_path)
		return true

	push_error("Save file format is invalid")
	return false

func reset_data() -> void:
	_persistent_data.clear()
	_runtime_state.clear()
	_initialize_data_structure()
	print("Game data reset to defaults")
