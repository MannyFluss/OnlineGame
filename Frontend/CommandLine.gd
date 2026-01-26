extends RichTextLabel

func _ready() -> void:
	GlobalInput.command_edited.connect(_on_command_edited)
	GlobalInput.command_entered.connect(_on_command_entered)
	
	
	
func _on_command_edited(command: String) -> void:
	var colored_text = _apply_word_colors(command)
	self.text = colored_text

	match randi_range(1,4):
		1:CommandInterface.execute_text_command("sfx click1")
		2:CommandInterface.execute_text_command("sfx click2")
		3:CommandInterface.execute_text_command("sfx click3")
		4:CommandInterface.execute_text_command("sfx click4")


func _apply_word_colors(_text: String) -> String:
	# Start with white as default color
	var result = "[color=#EEEEEE]" + _text + "[/color]"

	# Commands - blue color (#6594B1) + bold
	var blue_words = ["observe", "explore", "read", "play", "message", "clear"]
	for word in blue_words:
		result = TextManipulation.apply_tag_to_word(result, word, "color=#6594B1")
		result = TextManipulation.apply_tag_to_word(result, word, "tornado")

	# App names - mauve/red color (#DDAED3) + wave
	var red_words = ["basic1", "basic2", "tutorial"]
	for word in red_words:
		result = TextManipulation.apply_tag_to_word(result, word, "color=#DDAED3")
		result = TextManipulation.apply_tag_to_word(result, word, "wave")

	return result
	
func _on_command_entered(_command:String)->void:
	self.text=""
	match randi_range(1,4):
		1:CommandInterface.execute_text_command("sfx enter1")
		2:CommandInterface.execute_text_command("sfx enter2")
		3:CommandInterface.execute_text_command("sfx enter3")
		4:CommandInterface.execute_text_command("sfx enter4")
	
