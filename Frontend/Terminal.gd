extends Control
class_name Terminal

@onready var hud_text_label: RichTextLabel = %HudTextLabel
@onready var terminal_output_text_label: RichTextLabel = %TerminalOutputTextLabel
@onready var user_input_text_label: RichTextLabel = %UserInputTextLabel

func _ready() -> void:
	_verify_onready_references()

# Verifies all @onready member variables are properly initialized.
# Asserts if any member variables are null, providing a comma-separated list of missing references.
func _verify_onready_references() -> void:
	var missing = []
	for prop in get_property_list():
		if (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and get(prop.name) == null:
			missing.append(prop.name)
	assert(missing.size() == 0, "Null node references: " + ", ".join(missing))
