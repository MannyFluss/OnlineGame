extends RichTextLabel


func _ready() -> void:
	GlobalOutput.text_outputted.connect(_on_text_outputted)
	GlobalOutput.clear_outputted.connect(_on_clear_outputted)
	
func _on_text_outputted(command: String,_channel:String)->void:
	if _channel == "c":
		print(command) 
	if _channel!="":
		return
		#self.text = self.text + "\n"+"[channel]: "+_channel
	
	self.text = self.text + "\n"+command

func _on_clear_outputted()->void:
	self.text=""
