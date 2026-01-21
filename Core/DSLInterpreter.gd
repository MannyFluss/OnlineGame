extends Node
class_name DSLInterpreter

signal terminal_command(command_text: String)
signal timeline_started()
signal timeline_ended()
signal waiting_for_input(input_name: String)

enum State { IDLE, RUNNING, WAITING_INPUT, WAITING_TIME }

var _current_state: State = State.IDLE
var _instructions: Array = []
var _markers: Dictionary = {}
var _program_counter: int = 0
var _waiting_for: String = ""
var _time_remaining: float = 0.0


func load_file(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DSLInterpreter: Could not open file: %s" % path)
		return false

	var content = file.get_as_text()
	file.close()
	return parse(content)


func parse(content: String) -> bool:
	_instructions.clear()
	_markers.clear()
	_program_counter = 0

	var lines = content.split("\n")
	var instruction_index = 0
	var i = 0

	while i < lines.size():
		var line = lines[i]
		line = line.strip_edges()

		# Skip empty lines and comments
		if line.is_empty() or line.begins_with("#"):
			i += 1
			continue

		# Marker definition
		if line.begins_with(":"):
			var marker_name = line.substr(1).strip_edges()
			_markers[marker_name] = instruction_index
			i += 1
			continue

		# Check if line contains < (start of multi-line content)
		if line.contains("<"):
			var full_instruction = line
			# Accumulate lines until we find >
			while i < lines.size() and not full_instruction.contains(">"):
				i += 1
				if i < lines.size():
					full_instruction += "\n" + lines[i]

			var instruction = _parse_instruction(full_instruction)
			if instruction.is_empty():
				push_warning("DSLInterpreter: Could not parse instruction: %s" % full_instruction)
			else:
				_instructions.append(instruction)
				instruction_index += 1
		else:
			# Parse instruction
			var instruction = _parse_instruction(line)
			if instruction.is_empty():
				push_warning("DSLInterpreter: Could not parse line: %s" % line)
			else:
				_instructions.append(instruction)
				instruction_index += 1

		i += 1

	return true


func _parse_instruction(line: String) -> Dictionary:
	var parts = _split_respecting_quotes(line)
	if parts.is_empty():
		return {}

	var command = parts[0]
	var args = parts.slice(1)

	match command:
		"wait_input":
			if args.size() < 1:
				return {}
			return {"type": "wait_input", "input": args[0]}

		"wait_time":
			if args.size() < 1:
				return {}
			return {"type": "wait_time", "duration": float(args[0])}

		"jump":
			if args.size() < 1:
				return {}
			return {"type": "jump", "marker": args[0]}

		"if":
			return _parse_if(args)

		"cmd":
			# Everything after "cmd " is the terminal command
			var cmd_start = line.find("cmd ") + 4
			var cmd_text = line.substr(cmd_start).strip_edges()

			# Extract content between < and >
			var angle_start = cmd_text.find("<")
			var angle_end = cmd_text.rfind(">")
			if angle_start != -1 and angle_end != -1 and angle_end > angle_start:
				cmd_text = cmd_text.substr(angle_start + 1, angle_end - angle_start - 1)

			return {"type": "cmd", "text": cmd_text}

		_:
			push_warning("DSLInterpreter: Unknown command: %s" % command)
			return {}


func _parse_if(args: Array) -> Dictionary:
	# Format: if state.key operator value -> marker
	# Example: if state.score > 100 -> high_score
	var arrow_index = args.find("->")
	if arrow_index == -1 or arrow_index < 3:
		return {}

	var key = args[0]
	var operator = args[1]
	var value = args[2]
	var marker = args[arrow_index + 1] if arrow_index + 1 < args.size() else ""

	if marker.is_empty():
		return {}

	# Remove "state." prefix if present
	if key.begins_with("state."):
		key = key.substr(6)

	return {
		"type": "if",
		"key": key,
		"operator": operator,
		"value": _parse_value(value),
		"marker": marker
	}


func _parse_value(value_str: String):
	# Boolean
	if value_str == "true":
		return true
	if value_str == "false":
		return false

	# Number
	if value_str.is_valid_int():
		return int(value_str)
	if value_str.is_valid_float():
		return float(value_str)

	# String (strip quotes)
	if value_str.begins_with("\"") and value_str.ends_with("\""):
		return value_str.substr(1, value_str.length() - 2)

	return value_str


func _split_respecting_quotes(line: String) -> Array:
	var parts: Array = []
	var current = ""
	var in_quotes = false

	for c in line:
		if c == '"':
			in_quotes = not in_quotes
			current += c
		elif c == ' ' and not in_quotes:
			if not current.is_empty():
				parts.append(current)
				current = ""
		else:
			current += c

	if not current.is_empty():
		parts.append(current)

	return parts


func start() -> void:
	if _instructions.is_empty():
		push_error("DSLInterpreter: No instructions loaded")
		return

	_program_counter = 0
	_current_state = State.RUNNING
	timeline_started.emit()
	_execute_next()


func stop() -> void:
	_current_state = State.IDLE
	_program_counter = 0
	timeline_ended.emit()


func _execute_next() -> void:
	while _current_state == State.RUNNING and _program_counter < _instructions.size():
		var instruction = _instructions[_program_counter]
		_program_counter += 1

		var should_continue = _execute_instruction(instruction)
		if not should_continue:
			return

	# Reached end of instructions
	if _current_state == State.RUNNING:
		stop()


func _execute_instruction(instruction: Dictionary) -> bool:
	match instruction.type:
		"cmd":
			terminal_command.emit(instruction.text)
			return true

		"wait_input":
			_current_state = State.WAITING_INPUT
			_waiting_for = instruction.input
			waiting_for_input.emit(instruction.input)
			return false

		"wait_time":
			_current_state = State.WAITING_TIME
			_time_remaining = instruction.duration
			return false

		"jump":
			if _markers.has(instruction.marker):
				_program_counter = _markers[instruction.marker]
			else:
				push_error("DSLInterpreter: Unknown marker: %s" % instruction.marker)
			return true

		"if":
			var result = _evaluate_condition(instruction)
			if result and _markers.has(instruction.marker):
				_program_counter = _markers[instruction.marker]
			return true

	return true


func _evaluate_condition(instruction: Dictionary) -> bool:
	# Override this or connect to GlobalState
	# For now, return false for unknown keys
	var actual = _get_state_value(instruction.key)
	var expected = instruction.value

	match instruction.operator:
		"==":
			return actual == expected
		"!=":
			return actual != expected
		">":
			return actual > expected
		"<":
			return actual < expected
		">=":
			return actual >= expected
		"<=":
			return actual <= expected

	return false


func _get_state_value(key: String):
	# Override this method or connect to your GlobalState
	# Default implementation returns null
	return null


func receive_input(input_name: String) -> void:
	if _current_state != State.WAITING_INPUT:
		return

	if _waiting_for == input_name or _waiting_for == "any":
		_current_state = State.RUNNING
		_waiting_for = ""
		_execute_next()


func _process(delta: float) -> void:
	if _current_state == State.WAITING_TIME:
		_time_remaining -= delta
		if _time_remaining <= 0:
			_current_state = State.RUNNING
			_execute_next()


func is_running() -> bool:
	return _current_state != State.IDLE


func get_state() -> State:
	return _current_state
