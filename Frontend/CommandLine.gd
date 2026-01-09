extends RichTextLabel

func _ready() -> void:
	GlobalInput.command_edited.connect(_on_command_edited)
	GlobalInput.command_entered.connect(_on_command_entered)
	
	
	
func _on_command_edited(command:String)->void:
	self.text=command
	
	
func _on_command_entered(_command:String)->void:
	self.text=""
