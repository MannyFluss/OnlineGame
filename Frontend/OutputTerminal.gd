extends RichTextLabel


func _ready() -> void:
	GlobalInput.command_entered.connect(_on_command_inputed)
	pass
	
func _on_command_inputed(command: String)->void:
	print(command)
	self.text = self.text + "\n"+command
	
