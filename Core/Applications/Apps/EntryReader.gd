extends Application


func _input(_event: InputEvent) -> void:
	assert(false)
	if active==false:
		return

func start(_command:String,_stripped_commands:Array[String])->void:
	active=true
	push_error("function not implemented")
	assert(false)
	
func _physics_process(_delta: float) -> void:
	if active==false:
		return


func exit()->void:
	active=false
	push_error("function not implemented")
	
	assert(false)
	
