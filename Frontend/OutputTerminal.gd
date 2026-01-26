extends RichTextLabel

var _real_text: String = ""
var _target_display_length: int = 0
var _current_display_length: int = 0
var _time_since_last_update: float = 0.0
var _next_update_delay: float = 0.0

@export var typing_chaos_min: float = 0.01
@export var typing_chaos_max: float = 0.15
@export var clear_chaos_min: float = 0.01
@export var clear_chaos_max: float = 0.1
@export var adaptive_speed_enabled: bool = true
@export var speed_compensation_strength: float = 1.0

func _ready() -> void:
	GlobalOutput.text_outputted.connect(_on_text_outputted)
	GlobalOutput.clear_outputted.connect(_on_clear_outputted)

func _process(delta: float) -> void:
	if _current_display_length == _target_display_length:
		return

	_time_since_last_update += delta

	if _time_since_last_update >= _next_update_delay:
		_time_since_last_update = 0.0

		if _current_display_length < _target_display_length:
			_current_display_length += 1
			text = TextManipulation.build_display_with_n_chars(_real_text, _current_display_length)
			var remaining_text = _target_display_length - _current_display_length
			_next_update_delay = _get_adjusted_delay(typing_chaos_min, typing_chaos_max, remaining_text)

		elif _current_display_length > _target_display_length:
			_current_display_length -= 1
			text = TextManipulation.build_display_with_n_chars(_real_text, _current_display_length)
			var remaining_text = _current_display_length - _target_display_length
			_next_update_delay = _get_adjusted_delay(clear_chaos_min, clear_chaos_max, remaining_text)

func _on_text_outputted(command: String, _channel: String) -> void:
	if _channel == "c":
		print(command)
	if _channel != "":
		return

	var colored_command = TerminalColors.apply_color(command, "primary")
	_real_text = _real_text + "\n" + colored_command
	_target_display_length = TextManipulation.count_visible_chars(_real_text)
	_next_update_delay = randf_range(typing_chaos_min, typing_chaos_max)

func _on_clear_outputted() -> void:
	_real_text = ""
	_target_display_length = 0
	_next_update_delay = randf_range(clear_chaos_min, clear_chaos_max)

func _get_adjusted_delay(min_delay: float, max_delay: float, remaining_text: int) -> float:
	if not adaptive_speed_enabled or speed_compensation_strength == 0.0:
		return randf_range(min_delay, max_delay)

	# Calculate speed factor: more remaining text = faster typing
	# Uses logarithmic scale to avoid extreme speed changes
	var speed_factor = 1.0 + log(maxi(remaining_text, 1)) * 0.1 * speed_compensation_strength
	speed_factor = clamp(speed_factor, 0.3, 3.0)

	var adjusted_min = min_delay / speed_factor
	var adjusted_max = max_delay / speed_factor

	return randf_range(adjusted_min, adjusted_max)
