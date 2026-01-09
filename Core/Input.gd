extends Node

var test:int = 2


signal command_entered(String)

signal command_edited(String)

var _current_command = ""

# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_released():
			return
		if event.unicode > 0:
			_current_command = event.as_text_keycode() + _current_command
			command_edited.emit(_current_command)
			return
		if event.keycode==Key.KEY_SPACE:
			_current_command = _current_command + event.as_text_keycode()
			command_edited.emit(_current_command)
			return
		if event.keycode==Key.KEY_ENTER:
			command_entered.emit(_current_command)
			_current_command=""
			return
			
	
