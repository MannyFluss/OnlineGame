extends Node

enum States {
	TERMINAL,
	APPLICATION
}


var state :States=States.TERMINAL

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
		"observe":
			_handle_ls_command()
		"explore":
			_handle_cd_command(command)
		"read":
			_handle_read_command(command)
		"play":
			_handle_play_command(command)
		"file":
			pass
		"message":
			_handle_message_command(command)
		"clear":
			GlobalOutput.clear_output()
		"exit":
			_handle_exit_command()
		#make this automatic later cccc
		"basic":
			_handle_application_start(ApplicationLoader.instance.load_app("Basic"),[""])
		"basic2":
			_handle_application_start(ApplicationLoader.instance.load_app("Basic2"),[""])
		"tutorial":
			_handle_application_start(ApplicationLoader.instance.load_app("Tutorial"),[""])
		"sfx":
			_handle_sfx_command(command)
		"music":
			_handle_music_command(command)

func _handle_message_command(command: Command) -> void:
	if command.subcommand.size() < 3:
		GlobalOutput.send_to_output("Usage: message [channel] [message]")
		return
	if command.subcommand[2] == "clr":
		GlobalOutput.send_to_output("",command.subcommand[1])
		return
	var channel: String = command.subcommand[1]
	var message: String = command.raw_command.trim_prefix("message").strip_edges()
	message = message.trim_prefix(channel).strip_edges()

	GlobalOutput.send_to_output(message, channel)

func _handle_ls_command() -> void:
	var files: Array = FileExporler.get_files_in_directory()

	if files.is_empty():
		GlobalOutput.send_to_output("(empty directory)")
		return
	#"[color=cyan]Hello[/color] [color=magenta]World[/color]"
	var output: String = ""
	for file_info: Dictionary in files:
		if file_info["type"] == "folder":
			output += "[color=#EEEEEE]" + file_info["name"] + "[/color]\n"
		else:
			output += "[color=#DDAED3]" + file_info["name"] + "[/color]\n"

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
###pause standard input, save the state of the terminal output,
#await the app to send its close signal, back to normal.
#if app is already open that is a problem prevent it from opening and throw an Error


func _handle_sfx_command(command: Command) -> void:
	if command.subcommand.size() < 2:
		#GlobalOutput.send_to_output("Usage: sfx [filename]","debug")
		return

	var sfx_name: String = command.subcommand[1]
	SFX.play_sfx(sfx_name)
	#GlobalOutput.send_to_output("Playing SFX: " + sfx_name)

func _handle_music_command(command: Command) -> void:
	if command.subcommand.size() < 2:
		#GlobalOutput.send_to_output("Usage: music [filename|stop|random]")
		return

	var arg: String = command.subcommand[1]

	if arg == "stop":
		Music.stop()
		GlobalOutput.send_to_output("Music stopped","d")
	elif arg == "random":
		Music.play_random()
		GlobalOutput.send_to_output("Playing random song","d")
	else:
		Music.play_song(arg)
		GlobalOutput.send_to_output("Playing music: " + arg,"d")

func _handle_application_start(app:Application,_stripped_commands: Array[String])->void:
	if state==States.APPLICATION:
		push_error("Application already active (aborting new application)")
		return
	GlobalInput.enabled=false		
	state=States.APPLICATION
	
	app.start(_stripped_commands[0],_stripped_commands)
	await app.AppShutDown
	_handle_application_shutdown(app)

func _handle_application_shutdown(app:Application)->void:
	app.exit()
	state = States.TERMINAL
	GlobalInput.enabled=true


func _handle_exit_command() -> void:
	# Freeze the screen for a second by disabling input
	GlobalInput.enabled = false
	GlobalOutput.send_to_output("[color=DDAED3][wave][i][center]
	
	Bye Bye . . .", "exit_program")
	

	# Wait 1 second before quitting
	await get_tree().create_timer(2.5).timeout

	# Exit the application
	get_tree().quit()
