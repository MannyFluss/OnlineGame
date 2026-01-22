extends Application


const TIMELINE_PATH := "res://Core/Applications/Apps/TutorialApp/test_state_functions.txt"

const FRONTEND_SCENE := preload("res://Core/Applications/Apps/TutorialApp/TutorialFrontend.tscn")

var _interpreter: DSLInterpreter
var _frontend: Control


func start(_command: String, _stripped_commands: Array[String]) -> void:
	GlobalStateManager.runtime_state["tutorial"] = {}
	GlobalStateManager.runtime_state["tutorial"]["current_choice"] = 1
	GlobalStateManager.runtime_state["tutorial"]["current_choice_active"] = false
	
	
	
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

	if event.is_action_pressed("ui_accept"):
		if _interpreter and _interpreter.is_running():
			_interpreter.receive_input("space")


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
