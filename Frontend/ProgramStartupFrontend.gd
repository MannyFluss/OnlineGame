extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#wait for everything to get set up...
	await get_tree().process_frame
	
	CommandInterface.execute_text_command("music MainMenuTheme")
