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

func execute_text_command(command:String)->void:
	execute_command(_parse_command(command))

func _on_command_entered(command:String)->void:
	var command_to_exec:Command = _parse_command(command)
	execute_command(command_to_exec)

func _parse_command(command:String)->Command:
	var trimmed = command.strip_edges()
	var parts = trimmed.split(" ")

	if parts.size() == 0:
		printerr("Error parsing command: ", command)
		return null

	var main_command = parts[0]
	var subcommands: PackedStringArray = command.split(" ")

	return Command.new(main_command, subcommands, command)


func execute_command(command: Command)->void:
	match (command.command):
		"play":
			if command.subcommand.size() < 2:
				return
			Music.play_song(command.subcommand[1])
			
			
			
	pass
