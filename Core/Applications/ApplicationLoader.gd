extends Node
class_name ApplicationLoader
static var instance: ApplicationLoader = null

func _ready() -> void:
	instance = self
	for child in get_children():
		assert(child is Application)
			

func load_app(_name:String)->Application:
	var to_return : Application = get_node_or_null(_name)
	if to_return==null:
		push_error("app: ",_name," does not exist")
		assert(false)
	return to_return
