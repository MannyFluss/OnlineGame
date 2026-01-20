extends Application

func _input(_event: InputEvent) -> void:
	push_error("function not implemented")
	assert(false)
	if active==false:
		return

func _physics_process(_delta: float) -> void:
	if active==false:
		return

func start(_command:String, _stripped_commands: Array[String])->void:
	push_error("function not implemented")
	assert(false)
	active=true

func exit()->void:
	push_error("function not implemented")
	assert(false)
	
	active=false
	
