extends Application

const TIMELINE_PATH := "res://Core/Applications/Apps/TutorialApp/tutorial.dsl"

var _interpreter: DSLInterpreter


func start(_command: String, _stripped_commands: Array[String]) -> void:
	active = true
	print("[TutorialApp] Starting...")

	_interpreter = DSLInterpreter.new()
	add_child(_interpreter)

	_interpreter.command_emitted.connect(_on_command)
	_interpreter.terminal_command.connect(_on_terminal_command)
	_interpreter.timeline_started.connect(_on_timeline_started)
	_interpreter.timeline_ended.connect(_on_timeline_ended)
	_interpreter.waiting_for_input.connect(_on_waiting_for_input)

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
			print("[TutorialApp] Input received: space")
			_interpreter.receive_input("space")


func exit() -> void:
	print("[TutorialApp] Exiting...")

	if _interpreter:
		_interpreter.stop()
		_interpreter.queue_free()
		_interpreter = null

	active = false


func _on_command(command: String, args: Array) -> void:
	print("[TutorialApp] Command: %s | Args: %s" % [command, args])


func _on_terminal_command(command_text: String) -> void:
	print("[TutorialApp] Terminal command: %s" % command_text)
	CommandInterface.execute_text_command(command_text)


func _on_timeline_started() -> void:
	print("[TutorialApp] Timeline started")


func _on_timeline_ended() -> void:
	print("[TutorialApp] Timeline ended")
	shutdown_app()


func _on_waiting_for_input(input_name: String) -> void:
	print("[TutorialApp] Waiting for input: %s" % input_name)
