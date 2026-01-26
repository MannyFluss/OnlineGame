extends RichTextLabel

func _ready() -> void:
	GlobalInput.command_edited.connect(_on_command_edited)
	GlobalInput.command_entered.connect(_on_command_entered)
	
	
	
func _on_command_edited(command: String) -> void:
	self.text = TerminalColors.apply_color(command, "primary")
	
	
	
	match randi_range(1,4):
		1:CommandInterface.execute_text_command("sfx click1")
		2:CommandInterface.execute_text_command("sfx click2")
		3:CommandInterface.execute_text_command("sfx click3")
		4:CommandInterface.execute_text_command("sfx click4")
	
func _on_command_entered(_command:String)->void:
	self.text=""
	match randi_range(1,4):
		1:CommandInterface.execute_text_command("sfx enter1")
		2:CommandInterface.execute_text_command("sfx enter2")
		3:CommandInterface.execute_text_command("sfx enter3")
		4:CommandInterface.execute_text_command("sfx enter4")
	
