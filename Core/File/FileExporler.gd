extends Node

const FILE_EXPLORER_PATH: String = "res://Working/FileExplorer/"
const ROOT_FOLDER: String = "root"

var current_path: String = ""
var root_path: String = ""

func _ready() -> void:
	root_path = FILE_EXPLORER_PATH + ROOT_FOLDER
	current_path = root_path

func get_current_directory() -> String:
	return current_path

func set_current_directory(path: String) -> bool:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		current_path = path
		return true
	return false

func get_files_in_directory(path: String = "") -> Array:
	if path == "":
		path = current_path

	var files: Array = []
	var dir = DirAccess.open(ProjectSettings.globalize_path(path))

	if dir == null:
		return files

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = path.path_join(file_name)

		if dir.current_is_dir():
			files.append({
				"name": file_name,
				"type": "folder",
				"path": full_path
			})
		elif file_name.ends_with(".tres"):
			var resource = load(full_path)
			if resource is FileAbstract:
				files.append({
					"name": file_name,
					"type": "file",
					"path": full_path,
					"resource": resource
				})

		file_name = dir.get_next()

	return files

func get_file(file_name: String) -> FileAbstract:
	var files = get_files_in_directory()

	for file_info in files:
		if file_info["name"] == file_name and file_info["type"] == "file":
			return file_info["resource"]

	return null

func change_directory(folder_name: String) -> bool:
	var files = get_files_in_directory()

	for file_info in files:
		if file_info["name"] == folder_name and file_info["type"] == "folder":
			if set_current_directory(file_info["path"]):
				return true

	return false

func go_to_parent_directory() -> bool:
	if current_path == root_path:
		return false

	var parent_path = current_path.trim_suffix("/" + current_path.get_file())
	return set_current_directory(parent_path)
