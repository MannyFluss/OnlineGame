extends Node
class_name ApplicationLoader
static var instance: ApplicationLoader = null

func _ready() -> void:
	instance = self
	pass # Replace with function body.

func load_basic_app()->Application:
	return $BasicVisualApp
	
func load_basic_app_sequel()->Application:
	return $BasicVisualApp2
