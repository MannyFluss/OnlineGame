extends RichTextLabel

func _ready() -> void:
	GlobalInput.keycode_inputed.connect(_on_keycode_inputed)
	

func _on_keycode_inputed(event:InputEventKey)->void:
	if event.pressed:
		self.text += event.as_text_keycode().to_lower()
