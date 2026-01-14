extends Node
class_name FolderMetaData

var folder_properties: Dictionary = {}

func _ready() -> void:
	pass

func get_folder_info(folder_path: String) -> Dictionary:
	if folder_properties.has(folder_path):
		return folder_properties[folder_path]
	return {
		"name": folder_path.get_file(),
		"path": folder_path,
		"description": ""
	}

func set_folder_info(folder_path: String, info: Dictionary) -> void:
	folder_properties[folder_path] = info
