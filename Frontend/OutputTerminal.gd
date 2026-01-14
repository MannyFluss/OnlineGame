extends RichTextLabel


func _ready() -> void:
	GlobalOutput.text_outputted.connect(_on_text_outputted)
	GlobalOutput.clear_outputted.connect(_on_clear_outputted)
	
func _on_text_outputted(command: String)->void:
	print(command)
	self.text = self.text + "\n"+command

func _on_clear_outputted()->void:
	self.text=""
