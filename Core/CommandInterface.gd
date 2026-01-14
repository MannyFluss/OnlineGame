extends Node

class Command:
	var command:String=""
	var subcommand:PackedStringArray=[]
	var raw_command:String=""
	func _init(_command:String,_subcommand:PackedStringArray,_raw_command:String) -> void:
		command=_command
		subcommand=_subcommand
		raw_command=_raw_command
	pass

func _ready() -> void:
	GlobalInput.command_entered.connect(_on_command_entered)

func execute_text_command(command: String) -> void:
	var parsed_command: Command = _parse_command(command)
	if parsed_command != null:
		execute_command(parsed_command)

func _on_command_entered(command: String) -> void:
	var command_to_exec: Command = _parse_command(command)
	if command_to_exec != null:
		execute_command(command_to_exec)

func _parse_command(command: String) -> Command:
	var trimmed: String = command.strip_edges()
	var parts: PackedStringArray = trimmed.split(" ")

	if parts.size() == 0:
		printerr("Error parsing command: ", command)
		return null

	var main_command: String = parts[0]
	var subcommands: PackedStringArray = command.split(" ")

	return Command.new(main_command, subcommands, command)


func execute_command(command: Command) -> void:
	match (command.command):
		"ls":
			_handle_ls_command()
		"cd":
			_handle_cd_command(command)
		"read":
			_handle_read_command(command)
		"play":
			_handle_play_command(command)

func _handle_ls_command() -> void:
	var files: Array = FileExporler.get_files_in_directory()

	if files.is_empty():
		GlobalOutput.send_to_output("(empty directory)")
		return

	var output: String = ""
	for file_info: Dictionary in files:
		if file_info["type"] == "folder":
			output += "[FOLDER] " + file_info["name"] + "\n"
		else:
			output += "[FILE] " + file_info["name"] + "\n"

	GlobalOutput.send_to_output(output.strip_edges())

func _handle_cd_command(command: Command) -> void:
	if command.subcommand.size() < 2:
		GlobalOutput.send_to_output("Error: cd requires a folder name")
		return

	var folder_name: String = command.subcommand[1]

	if folder_name == "..":
		if FileExporler.go_to_parent_directory():
			GlobalOutput.send_to_output("Changed to parent directory")
		else:
			GlobalOutput.send_to_output("Error: Already at root directory")
	else:
		if FileExporler.change_directory(folder_name):
			GlobalOutput.send_to_output("Changed to directory: " + folder_name)
		else:
			GlobalOutput.send_to_output("Error: Directory not found: " + folder_name)

func _handle_read_command(command: Command) -> void:
	if command.subcommand.size() < 2:
		GlobalOutput.send_to_output("Error: read requires a file name")
		return

	var file_name: String = command.subcommand[1]
	var file: FileAbstract = FileExporler.get_file(file_name)

	if file == null:
		GlobalOutput.send_to_output("Error: File not found: " + file_name)
		return

	if file is FileEntry:
		GlobalOutput.send_to_output(file.my_text_entry)
	else:
		GlobalOutput.send_to_output("Error: File is not an entry type")

func _handle_play_command(command: Command) -> void:
	if command.subcommand.size() < 2:
		GlobalOutput.send_to_output("Error: play requires a file name")
		return

	var file_name: String = command.subcommand[1]
	var file: FileAbstract = FileExporler.get_file(file_name)

	if file == null:
		GlobalOutput.send_to_output("Error: File not found: " + file_name)
		return

	if file is FileSong:
		Music.play_song(file.song_name)
		GlobalOutput.send_to_output("Playing: " + file.song_name)
	else:
		Music.play_song(file_name)
		GlobalOutput.send_to_output("Playing: " + file_name)
