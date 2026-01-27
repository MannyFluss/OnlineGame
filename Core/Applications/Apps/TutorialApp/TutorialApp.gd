extends Application


const TIMELINE_PATH := "res://Core/Applications/Apps/TutorialApp/tutorial.txt"

const FRONTEND_SCENE := preload("res://Core/Applications/Apps/TutorialApp/TutorialFrontend.tscn")

var _interpreter: DSLInterpreter
var _frontend: Control


func _ready() -> void:
	GlobalStateManager.runtime_changed.connect(on_runtime_var_changed)

func start(_command: String, _stripped_commands: Array[String]) -> void:
	
	GlobalStateManager.set_runtime("tutorial_choice",1)
	GlobalStateManager.set_runtime("tutorial_choice_active",false)
	
	
	
	
	active = true
	print("[TutorialApp] Starting...")

	# Load frontend
	_frontend = FRONTEND_SCENE.instantiate()
	add_child(_frontend)

	# Create interpreter
	_interpreter = DSLInterpreter.new()
	add_child(_interpreter)

	_interpreter.terminal_command.connect(_on_terminal_command)
	_interpreter.timeline_ended.connect(_on_timeline_ended)

	if _interpreter.load_file(TIMELINE_PATH):
		print("[TutorialApp] Timeline loaded successfully")
		_interpreter.start()
	else:
		print("[TutorialApp] Failed to load timeline")


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_left"):
		GlobalStateManager.set_runtime("tutorial_choice",GlobalStateManager.get_runtime("tutorial_choice")-1)
	if event.is_action_pressed("ui_right"):
		GlobalStateManager.set_runtime("tutorial_choice",GlobalStateManager.get_runtime("tutorial_choice")+1)
	
	
	if event.is_action_pressed("ui_accept"):
		if _interpreter and _interpreter.is_running():
			_interpreter.receive_input("space")

func on_runtime_var_changed(path:String, value :Variant)->void:
	print("Global state manager ", path, ":", value)
	if path == "tutorial_choice" and GlobalStateManager.get_runtime("tutorial_choice_active"):
		var current_choice = GlobalStateManager.get_runtime("tutorial_choice")
		match current_choice:
			1: CommandInterface.execute_text_command("message tutorial_player *option1 option2 option3")
			2: CommandInterface.execute_text_command("message tutorial_player option1 *option2 option3")
			3: CommandInterface.execute_text_command("message tutorial_player option1 option2 *option3")
			
	

func exit() -> void:
	print("[TutorialApp] Exiting...")

	if _interpreter:
		_interpreter.stop()
		_interpreter.queue_free()
		_interpreter = null

	if _frontend:
		_frontend.queue_free()
		_frontend = null

	active = false


func _on_terminal_command(command_text: String) -> void:
	CommandInterface.execute_text_command(command_text) 


func _on_timeline_ended() -> void:
	print("[TutorialApp] Timeline ended")
	shutdown_app()
