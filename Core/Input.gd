extends Node

var test:int = 2

signal keycode_inputed(InputEventKey)

# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		keycode_inputed.emit(event)
