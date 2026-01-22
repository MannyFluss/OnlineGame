# DSL Timeline Reference

A simple domain-specific language for scripting linear and branching timelines in the game. The DSL separates sequence logic from visual/audio implementation.

## File Format

- Plain text files (recommended extension: `.dsl`)
- One instruction per line
- Lines are processed top-to-bottom
- Whitespace at start/end of lines is ignored

## Comments

Lines starting with `#` are ignored.

```
# This is a comment
cmd message tutorial Hello  # inline comments are NOT supported
```

## Markers

Markers define named positions in the timeline that can be jumped to.

**Syntax:** `:marker_name`

```
:start
:game_over
:secret_ending
```

- Marker names should be lowercase with underscores
- Markers don't execute anything, they just mark positions
- Multiple jumps can target the same marker

## Commands

### wait_input

Pauses execution until a specific input is received.

**Syntax:** `wait_input <input_name>`

```
wait_input space
wait_input confirm
wait_input any
```

- `any` is a special value that accepts any input
- Input names are arbitrary strings - your game code calls `receive_input("space")` to resume
- The `waiting_for_input` signal is emitted when waiting begins

### wait_time

Pauses execution for a duration.

**Syntax:** `wait_time <seconds>`

```
wait_time 2.5
wait_time 0.5
```

- Duration is in seconds (float)
- Execution resumes automatically after the time elapses

### cmd

Sends a raw command string to the terminal. The entire text after `cmd ` is passed as-is.

**Syntax:** `cmd <terminal_command>`

```
cmd play_song epic_battle
cmd echo Hello from the timeline!
cmd set_volume 0.5
```

- Everything after `cmd ` is captured as the command text
- Emits the `terminal_command` signal with the full command string
- Your game code handles the command via signal connection

### jump

Unconditionally moves execution to a marker.

**Syntax:** `jump <marker_name>`

```
jump start
jump game_over
```

- If the marker doesn't exist, an error is logged and execution continues
- Can jump forward or backward
- Useful for loops and skipping sections

### if

Conditionally jumps to a marker based on game state.

**Syntax:** `if <key> <operator> <value> -> <marker_name>`

```
if score > 100 -> high_score_path
if tutorial_complete == true -> skip_tutorial
if lives <= 0 -> game_over
if name == "secret" -> easter_egg
```

**Operators:**
- `==` equal
- `!=` not equal
- `>` greater than
- `<` less than
- `>=` greater than or equal
- `<=` less than or equal

**Values:**
- `true` / `false` - booleans
- `123` / `45.67` - numbers
- `"quoted string"` - strings

**Notes:**
- Optional `state.` prefix is stripped: `state.score` and `score` are equivalent
- If condition is false, execution continues to the next line
- If condition is true, execution jumps to the marker
- Override `_get_state_value()` in a subclass to connect to your state manager

## Signals

The interpreter emits these signals:

| Signal | Parameters | Description |
|--------|------------|-------------|
| `terminal_command` | `command_text: String` | A `cmd` instruction executed |
| `timeline_started` | none | `start()` was called |
| `timeline_ended` | none | Reached end or `stop()` was called |
| `waiting_for_input` | `input_name: String` | Now waiting for input |

## API Reference

### Loading and Running

```gdscript
var interpreter = DSLInterpreter.new()

# Load from file
interpreter.load_file("res://path/to/timeline.dsl")

# Or parse a string directly
interpreter.parse("""
:start
cmd message app Hello
wait_input space
cmd message app Goodbye
""")

# Start execution
interpreter.start()

# Stop execution early
interpreter.stop()
```

### Providing Input

```gdscript
# When the player presses space
interpreter.receive_input("space")

# When the player makes a choice
interpreter.receive_input("left")
interpreter.receive_input("right")
interpreter.receive_input("confirm")
```

### Checking State

```gdscript
# Check if timeline is active
if interpreter.is_running():
	pass

# Get detailed state
match interpreter.get_state():
	DSLInterpreter.State.IDLE:
		print("Not running")
	DSLInterpreter.State.RUNNING:
		print("Executing")
	DSLInterpreter.State.WAITING_INPUT:
		print("Waiting for input")
	DSLInterpreter.State.WAITING_TIME:
		print("Waiting for timer")
```

### Connecting to Game State

Override `_get_state_value()` in a subclass:

```gdscript
class_name GameDSLInterpreter
extends DSLInterpreter

func _get_state_value(key: String):
	return GlobalState.get_value(key, null)
```

### Handling Terminal Commands

Connect to the `terminal_command` signal:

```gdscript
interpreter.terminal_command.connect(_on_terminal_command)

func _on_terminal_command(command_text: String) -> void:
	CommandInterface.execute_text_command(command_text)
```

Commands are sent through the global command interface using `cmd message <channel> <text>`. Frontends subscribe to specific channels via `GlobalOutput.text_outputted`.

## Complete Example

```
# tutorial.dsl - A simple tutorial sequence

:start
cmd message tutorial_face smile
cmd message tutorial Welcome to the game!
cmd message tutorial_player [Press SPACE to continue]
wait_input space

cmd message tutorial_face neutral
cmd message tutorial Let's check your progress.
cmd message tutorial_player
if tutorial_complete == true -> already_done

:show_tutorial
cmd message tutorial This is how you play...
cmd message tutorial_player [Press SPACE to continue]
wait_input space
jump end

:already_done
cmd message tutorial_face smile
cmd message tutorial You've already completed the tutorial!
cmd message tutorial_player [Press SPACE to continue]
wait_input space

:end
cmd message tutorial_face neutral
cmd message tutorial Good luck!
cmd message tutorial_player
wait_time 2.0
```

## Error Handling

The interpreter is designed to be crash-resistant:

- Unknown commands log a warning and are skipped
- Missing markers log an error but don't crash
- Missing state keys return `null` (override `_get_state_value` to customize)
- Malformed lines log a warning and are skipped
- Empty files or no instructions log an error on `start()`

Check the Godot output panel for warnings and errors during development.
