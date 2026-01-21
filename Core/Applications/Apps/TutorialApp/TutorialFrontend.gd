@tool
extends Control

const CHANNEL_TEXT := "tutorial"
const CHANNEL_FACE := "tutorial_face"
const CHANNEL_PLAYER := "tutorial_player"

@onready var tutorial_johnson_output: RichTextLabel = %TutorialJohnsonOutput
@onready var player_text: RichTextLabel = %PlayerText
@onready var tutorial_drawing: TutorialDrawing = $Control/VBoxContainer/Control/HBoxContainer/MarginContainer/TutorialDrawing


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	GlobalOutput.text_outputted.connect(_on_text_outputted)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	if GlobalOutput.text_outputted.is_connected(_on_text_outputted):
		GlobalOutput.text_outputted.disconnect(_on_text_outputted)


func _on_text_outputted(data: String, channel: String) -> void:
	match channel:
		CHANNEL_TEXT:
			_set_output_text(data)
		CHANNEL_FACE:
			_set_face(data)
		CHANNEL_PLAYER:
			_set_player_text(data)


func _set_face(face_name: String) -> void:
	if tutorial_drawing:
		tutorial_drawing.current_face = face_name


func _set_output_text(text: String) -> void:
	if tutorial_johnson_output:
		tutorial_johnson_output.text = text


func _set_player_text(text: String) -> void:
	if player_text:
		player_text.text = text
