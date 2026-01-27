class_name TerminalColors


# Color palette - based on paper aesthetic
# Paper background: cream/off-white
# Ink: dark navy blue
# Accents: medium blue and soft mauve
# Borders: decorative pink

# [color=213C51]
# [color=6594B1]
# [color=DDAED3]
# [color=EEEEEE]
const PRIMARY_TEXT = Color("#213C51")      # Dark navy - main text               # [color=213C51]
const SECONDARY_TEXT = Color("#6594B1")    # Medium blue - emphasis/prompts      # [color=6594B1]
const ACCENT = Color("#DDAED3")            # Soft mauve - decorative/highlights  # [color=DDAED3]
const PAPER_BG = Color("#EEEEEE")          # Off-white - background              # [color=EEEEEE]

# Semantic color mapping
const COLOR_INPUT = PRIMARY_TEXT           # User input text
const COLOR_OUTPUT = PRIMARY_TEXT          # Terminal output
const COLOR_COMMAND = SECONDARY_TEXT       # Commands
const COLOR_PROMPT = SECONDARY_TEXT        # > prompt
const COLOR_ERROR = ACCENT                 # Error messages
const COLOR_SUCCESS = SECONDARY_TEXT       # Success messages
const COLOR_BACKGROUND = PAPER_BG          # Panel backgrounds


static func get_color_hex(color_name: String) -> String:
	match color_name:
		"primary":
			return "213C51"
		"secondary":
			return "6594B1"
		"accent":
			return "DDAED3"
		"paper":
			return "EEEEEE"
		_:
			return "213C51"


static func apply_color(text: String, color_name: String) -> String:
	var color_hex = get_color_hex(color_name)
	return "[color=#%s]%s[/color]" % [color_hex, text]
