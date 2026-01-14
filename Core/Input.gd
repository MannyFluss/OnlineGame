extends Node

var test:int = 2


signal command_entered(String)

signal command_edited(String)

var _current_command = ""

var shifting = false
# Called when the node enters the scene tree for the first time.

#replace this entire piece of shit with a text edit
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		print(event.as_text_keycode())
		if event.is_released():
			return
		
		if event.as_text_keycode().length() == 1 or (event.as_text_keycode().begins_with("Shift+") 
		and event.as_text_keycode().length()==7):
			var individual_key="a"
			if event.as_text_keycode().length()==1:
				individual_key = event.as_text_keycode().to_lower()
			if event.as_text_keycode().length()==7:
				individual_key = event.as_text_keycode()[6]
			_current_command=_current_command+individual_key
			command_edited.emit(_current_command)
			return
		if event.keycode==Key.KEY_SHIFT:
			shifting=true
		if event.keycode==Key.KEY_SPACE:
			_current_command = _current_command+" "
			command_edited.emit(_current_command)
			return
		if event.keycode==Key.KEY_PERIOD:
			_current_command = _current_command+"."
			command_edited.emit(_current_command)
			return
		if event.keycode==Key.KEY_BACKSPACE:
			if _current_command.length() > 0:
				_current_command = _current_command.erase(_current_command.length()-1,1)
				command_edited.emit(_current_command)
			return
		if event.keycode==Key.KEY_ENTER:
			command_entered.emit(_current_command)
			_current_command=""
			return
			
	
