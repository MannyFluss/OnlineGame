extends Node

const SAVE_PATH = "user://saves/"
const SAVE_FILE = "save_slot_1.json"

var persistent_data: Dictionary = {}
var runtime_state: Dictionary = {}

func _ready() -> void:
	_initialize_data_structure()
	load_game()

func _initialize_data_structure() -> void:
	# Initialize the persistent data with empty categories
	persistent_data = {
		"statistics": {
			"high_scores": {}
		},
		"dialogue": {
			"visited_locations": [],
			"completed_quests": [],
			"talked_to_characters": [],
			"dialogue_flags": {}
		},
		"settings": {
			"volume": 0.8
		}
	}

	# Initialize runtime state (not saved)
	runtime_state = {
		"current_scene": "",
		"is_playing": false
	}

func get_high_score(game_name: String) -> int:
	return persistent_data["statistics"]["high_scores"].get(game_name, 0)

func set_high_score(game_name: String, score: int) -> void:
	if score > get_high_score(game_name):
		persistent_data["statistics"]["high_scores"][game_name] = score

func get_dialogue_flag(flag_name: String, default_value = null):
	return persistent_data["dialogue"]["dialogue_flags"].get(flag_name, default_value)

func set_dialogue_flag(flag_name: String, value) -> void:
	persistent_data["dialogue"]["dialogue_flags"][flag_name] = value

func add_location_visit(location_name: String) -> void:
	if location_name not in persistent_data["dialogue"]["visited_locations"]:
		persistent_data["dialogue"]["visited_locations"].append(location_name)

func has_visited(location_name: String) -> bool:
	return location_name in persistent_data["dialogue"]["visited_locations"]

func add_quest_completion(quest_name: String) -> void:
	if quest_name not in persistent_data["dialogue"]["completed_quests"]:
		persistent_data["dialogue"]["completed_quests"].append(quest_name)

func has_completed_quest(quest_name: String) -> bool:
	return quest_name in persistent_data["dialogue"]["completed_quests"]

func add_character_conversation(character_name: String) -> void:
	if character_name not in persistent_data["dialogue"]["talked_to_characters"]:
		persistent_data["dialogue"]["talked_to_characters"].append(character_name)

func has_talked_to(character_name: String) -> bool:
	return character_name in persistent_data["dialogue"]["talked_to_characters"]

func save_game() -> bool:
	# Create save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_absolute(SAVE_PATH)
		
	var json_string = JSON.stringify(persistent_data)
	var file = FileAccess.open(SAVE_PATH + SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save game: could not open file")
		return false

	file.store_string(json_string)
	print("Game saved successfully to: ", SAVE_PATH + SAVE_FILE)
	return true

func load_game() -> bool:
	var file_path = SAVE_PATH + SAVE_FILE

	# If save file doesn't exist, use defaults
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
		# Merge loaded data with defaults to handle missing keys
		_merge_dictionaries(persistent_data, loaded_data)
		print("Game loaded successfully from: ", file_path)
		return true

	push_error("Save file format is invalid")
	return false

func _merge_dictionaries(target: Dictionary, source: Dictionary) -> void:
	# Merge source into target, preserving target's structure
	for key in source:
		if key in target and target[key] is Dictionary and source[key] is Dictionary:
			_merge_dictionaries(target[key], source[key])
		else:
			target[key] = source[key]

func reset_data() -> void:
	persistent_data.clear()
	_initialize_data_structure()
	print("Game data reset to defaults")
