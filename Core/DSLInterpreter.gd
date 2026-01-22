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

	var tokens = _tokenize(content)
	var instruction_index = 0

	for token in tokens:
		# Marker definition
		if token.begins_with(":"):
			var marker_name = token.substr(1).strip_edges()
			_markers[marker_name] = instruction_index
			continue

		# Parse instruction
		var instruction = _parse_instruction(token)
		if instruction.is_empty():
			push_warning("DSLInterpreter: Could not parse: %s" % token.substr(0, min(50, token.length())))
		else:
			_instructions.append(instruction)
			instruction_index += 1

	return true


func _tokenize(content: String) -> Array:
	var tokens: Array = []
	var i = 0
	var length = content.length()

	while i < length:
		# Skip whitespace between tokens
		while i < length and content[i] in [' ', '\t', '\n', '\r']:
			i += 1

		if i >= length:
			break

		# Comment - skip to end of line
		if content[i] == '#':
			while i < length and content[i] != '\n':
				i += 1
			continue

		# Marker - read until end of line or whitespace
		if content[i] == ':':
			var start = i
			i += 1
			while i < length and content[i] not in [' ', '\t', '\n', '\r']:
				i += 1
			tokens.append(content.substr(start, i - start))
			continue

		# Bracket-delimited instruction: <...>
		if content[i] == '<':
			var start = i + 1
			var depth = 1
			i += 1
			while i < length and depth > 0:
				if content[i] == '<':
					depth += 1
				elif content[i] == '>':
					depth -= 1
				i += 1
			var inner = content.substr(start, i - start - 1)
			tokens.append(inner.strip_edges())
			continue

		# Non-bracketed instruction - read until we hit < or newline
		var start = i
		while i < length:
			if content[i] == '\n':
				i += 1
				break
			if content[i] == '<':
				# Command followed by <content>
				var cmd_part = content.substr(start, i - start)
				i += 1  # skip <
				var content_start = i
				var depth = 1
				while i < length and depth > 0:
					if content[i] == '<':
						depth += 1
					elif content[i] == '>':
						depth -= 1
					i += 1
				var bracket_content = content.substr(content_start, i - content_start - 1)
				# Combine: "cmd message tutorial" + content
				tokens.append(cmd_part.strip_edges() + "\n" + bracket_content)
				start = -1
				break
			i += 1

		if start != -1 and i > start:
			var line = content.substr(start, i - start).strip_edges()
			if not line.is_empty():
				tokens.append(line)

	return tokens


func _parse_instruction(token: String) -> Dictionary:
	# Find the command (first word)
	var first_space = -1
	var first_newline = token.find("\n")

	for j in range(token.length()):
		if token[j] == ' ' or token[j] == '\t':
			first_space = j
			break

	var command: String
	var rest: String

	if first_space == -1 and first_newline == -1:
		command = token
		rest = ""
	elif first_newline != -1 and (first_space == -1 or first_newline < first_space):
		command = token.substr(0, first_newline).strip_edges()
		rest = token.substr(first_newline + 1)
	else:
		command = token.substr(0, first_space)
		rest = token.substr(first_space + 1)

	match command:
		"wait_input":
			return {"type": "wait_input", "input": rest.strip_edges()}

		"wait_time":
			return {"type": "wait_time", "duration": float(rest.strip_edges())}

		"jump":
			return {"type": "jump", "marker": rest.strip_edges()}

		"if":
			return _parse_if(rest)

		"cmd":
			return {"type": "cmd", "text": rest}

		_:
			push_warning("DSLInterpreter: Unknown command: %s" % command)
			return {}


func _parse_if(rest: String) -> Dictionary:
	# Format: state.key operator value -> marker
	var parts = _split_respecting_quotes(rest)

	var arrow_index = parts.find("->")
	if arrow_index == -1 or arrow_index < 3:
		return {}

	var key = parts[0]
	var operator = parts[1]
	var value = parts[2]
	var marker = parts[arrow_index + 1] if arrow_index + 1 < parts.size() else ""

	if marker.is_empty():
		return {}

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
	if value_str == "true":
		return true
	if value_str == "false":
		return false

	if value_str.is_valid_int():
		return int(value_str)
	if value_str.is_valid_float():
		return float(value_str)

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
