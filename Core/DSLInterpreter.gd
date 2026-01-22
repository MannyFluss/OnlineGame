extends Node
class_name DSLInterpreter

signal terminal_command(command_text: String)
signal timeline_started()
signal timeline_ended()
signal waiting_for_input(input_name: String)
signal DSL_file_signal(signal_name:String)

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
			return _parse_wait_input(rest)

		"wait_time":
			return {"type": "wait_time", "duration": float(rest.strip_edges())}

		"jump":
			return {"type": "jump", "marker": rest.strip_edges()}

		"cmd":
			return {"type": "cmd", "text": rest}

		"signal":
			return _parse_signal(rest)

		"if":
			return _parse_if(rest)

		"set_runtime":
			return _parse_set_runtime(rest)

		"set_persistent":
			return _parse_set_persistent(rest)

		_:
			push_warning("DSLInterpreter: Unknown command: %s" % command)
			return {}


func _parse_signal(rest: String) -> Dictionary:
	var function_name = rest.strip_edges()

	if function_name.is_empty():
		return {}

	return {
		"type": "signal",
		"function": function_name
	}


func _parse_set_runtime(rest: String) -> Dictionary:
	var parts = rest.split(" ", false, 1)
	if parts.size() < 2:
		push_warning("DSLInterpreter: Invalid set_runtime syntax, expected 'key value': %s" % rest)
		return {}

	var key = parts[0].strip_edges()
	var value = _parse_value(parts[1].strip_edges())

	return {
		"type": "set_runtime",
		"key": key,
		"value": value
	}


func _parse_set_persistent(rest: String) -> Dictionary:
	var parts = rest.split(" ", false, 1)
	if parts.size() < 2:
		push_warning("DSLInterpreter: Invalid set_persistent syntax, expected 'key value': %s" % rest)
		return {}

	var key = parts[0].strip_edges()
	var value = _parse_value(parts[1].strip_edges())

	return {
		"type": "set_persistent",
		"key": key,
		"value": value
	}


func _parse_wait_input(rest: String) -> Dictionary:
	# Format: input_name or input_name -> marker_name
	var parts = rest.split("->", false)
	var input_name = parts[0].strip_edges()
	var marker = ""

	if parts.size() > 1:
		marker = parts[1].strip_edges()

	return {"type": "wait_input", "input": input_name, "marker": marker}


func _parse_if(rest: String) -> Dictionary:
	# Format: GlobalStateManager.path operator value -> marker_name
	var parts = rest.split("->", false)
	if parts.size() != 2:
		push_warning("DSLInterpreter: Invalid if syntax, expected '-> marker': %s" % rest)
		return {}

	var condition_str = parts[0].strip_edges()
	var marker = parts[1].strip_edges()

	# Parse the condition: path operator value
	# Operators: ==, !=, >=, <=, >, <
	var operator = ""
	var operator_pos = -1

	# Check operators in order (longer first to avoid partial matches)
	for op in ["==", "!=", ">=", "<=", ">", "<"]:
		var pos = condition_str.find(op)
		if pos != -1:
			operator = op
			operator_pos = pos
			break

	if operator.is_empty():
		push_warning("DSLInterpreter: No operator found in if condition: %s" % rest)
		return {}

	var path = condition_str.substr(0, operator_pos).strip_edges()
	var value_str = condition_str.substr(operator_pos + operator.length()).strip_edges()

	return {
		"type": "if",
		"path": path,
		"operator": operator,
		"value": _parse_value(value_str),
		"marker": marker
	}


func _evaluate_condition(instruction: Dictionary) -> bool:
	var actual_value = _get_state_value_from_path(instruction.path)

	if actual_value == null:
		return false

	var expected_value = instruction.value
	var operator = instruction.operator

	match operator:
		"==":
			return actual_value == expected_value
		"!=":
			return actual_value != expected_value
		">":
			return actual_value > expected_value
		"<":
			return actual_value < expected_value
		">=":
			return actual_value >= expected_value
		"<=":
			return actual_value <= expected_value
		_:
			push_error("DSLInterpreter: Unknown operator: %s" % operator)
			return false


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


func _get_state_value_from_path(path: String) -> Variant:
	# Parse paths like: GlobalStateManager.runtime_state["key"]["nested"]
	# or: GlobalStateManager.persistent_data["key"]["nested"]

	if not path.begins_with("GlobalStateManager."):
		push_warning("DSLInterpreter: Invalid state path: %s" % path)
		return null

	var remainder = path.substr("GlobalStateManager.".length())

	# Extract state type (runtime_state or persistent_data)
	var state_type = ""
	var keys_start = -1

	if remainder.begins_with("runtime_state"):
		state_type = "runtime_state"
		keys_start = "runtime_state".length()
	elif remainder.begins_with("persistent_data"):
		state_type = "persistent_data"
		keys_start = "persistent_data".length()
	else:
		push_warning("DSLInterpreter: Unknown state type in path: %s" % path)
		return null

	# Extract all keys from bracket notation: ["key"]["nested"]...
	var keys: Array = []
	var bracket_pattern = RegEx.new()
	bracket_pattern.compile("\\[\"([^\"]+)\"\\]")

	var matches = bracket_pattern.search_all(remainder.substr(keys_start))
	for match in matches:
		keys.append(match.get_string(1))

	if keys.is_empty():
		push_warning("DSLInterpreter: No keys found in state path: %s" % path)
		return null

	# Get the state dictionary
	var state_dict = null
	if state_type == "runtime_state":
		state_dict = GlobalStateManager._runtime_state #read only operation
	else:
		state_dict = GlobalStateManager._persistent_data #read only operation

	# Traverse the nested dictionary
	var current = state_dict
	for key in keys:
		if current is Dictionary and key in current:
			current = current[key]
		else:
			# Key doesn't exist, return null
			return null

	return current


func _substitute_variables(text: String) -> String:
	var result = text

	# Pattern 1: {GlobalStateManager.get_runtime("key")}
	var runtime_pattern = RegEx.new()
	runtime_pattern.compile("\\{GlobalStateManager\\.get_runtime\\(\"([^\"]+)\"\\)\\}")
	var runtime_matches = runtime_pattern.search_all(text)
	for match in runtime_matches:
		var full_pattern = match.get_string(0)
		var key = match.get_string(1)
		var value = GlobalStateManager.get_runtime(key)
		if value != null:
			result = result.replace(full_pattern, str(value))

	# Pattern 2: {GlobalStateManager.get_persistent("key")}
	var persistent_pattern = RegEx.new()
	persistent_pattern.compile("\\{GlobalStateManager\\.get_persistent\\(\"([^\"]+)\"\\)\\}")
	var persistent_matches = persistent_pattern.search_all(text)
	for match in persistent_matches:
		var full_pattern = match.get_string(0)
		var key = match.get_string(1)
		var value = GlobalStateManager.get_persistent(key)
		if value != null:
			result = result.replace(full_pattern, str(value))

	return result


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
			var substituted_text = _substitute_variables(instruction.text)
			terminal_command.emit(substituted_text)
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
			if _evaluate_condition(instruction):
				if _markers.has(instruction.marker):
					_program_counter = _markers[instruction.marker]
				else:
					push_error("DSLInterpreter: Unknown marker: %s" % instruction.marker)
			return true

		"signal":
			_call_target_function(instruction.function)
			return true

		"set_runtime":
			GlobalStateManager.set_runtime(instruction.key, instruction.value)
			return true

		"set_persistent":
			GlobalStateManager.set_persistent(instruction.key, instruction.value)
			return true

	return true




func _call_target_function(_signal_name: String) -> void:
	push_error("not implemented")



func receive_input(input_name: String) -> void:
	if _current_state != State.WAITING_INPUT:
		return

	if _waiting_for == input_name or _waiting_for == "any":
		_current_state = State.RUNNING
		_waiting_for = ""

		# Check if the current instruction has a jump marker
		if _program_counter > 0:
			var prev_instruction = _instructions[_program_counter - 1]
			if prev_instruction.type == "wait_input" and prev_instruction.has("marker") and prev_instruction.marker != "":
				if _markers.has(prev_instruction.marker):
					_program_counter = _markers[prev_instruction.marker]
				else:
					push_error("DSLInterpreter: Unknown marker: %s" % prev_instruction.marker)

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
