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

**Syntax:** `wait_input <input_name>` or `wait_input <input_name> -> <marker_name>`

```
wait_input space
wait_input confirm
wait_input any
wait_input space -> next_section
wait_input any -> continue
```

- `any` is a special value that accepts any input
- Input names are arbitrary strings - your game code calls `receive_input("space")` to resume
- The `waiting_for_input` signal is emitted when waiting begins
- Optional `-> marker_name` jumps to the marker when the input is received
- Without a marker, execution continues to the next line after input

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

**Variable Substitution:**

You can embed state values in commands using `{GlobalStateManager.get_runtime("key")}` or `{GlobalStateManager.get_persistent("key")}` syntax. They're replaced before sending:

```
cmd message tutorial Your score is: {GlobalStateManager.get_persistent("high_score")}
cmd message tutorial Current choice: {GlobalStateManager.get_runtime("tutorial_choice")}
cmd message tutorial Volume: {GlobalStateManager.get_persistent("volume")}
```

Variables that don't exist return `null` and remain unchanged.

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

### signal

Calls a function on the state provider node.

**Syntax:** `signal <function_name>`

```
signal player_scored
signal unlock_achievement
signal on_tutorial_complete
signal trigger_checkpoint
```

**Notes:**
- The function must exist on the state_provider node
- The function is called with no arguments
- The state_provider is typically the frontend/app that manages game state
- Use this to trigger events or callbacks in your game

### set_runtime

Sets a value in GlobalStateManager's runtime state.

**Syntax:** `set_runtime <key> <value>`

```
set_runtime current_choice 1
set_runtime tutorial_complete true
set_runtime player_name "Alice"
```

- Value is parsed as a boolean (`true`/`false`), number, or string
- Runtime state is temporary and not saved between sessions

### set_persistent

Sets a value in GlobalStateManager's persistent data.

**Syntax:** `set_persistent <key> <value>`

```
set_persistent high_score 500
set_persistent level_unlocked 3
set_persistent player_name "Bob"
```

- Value is parsed as a boolean (`true`/`false`), number, or string
- Persistent data is saved when you call `GlobalStateManager.save_game()`

### if

Conditionally jumps to a marker based on GlobalStateManager state.

**Syntax:** `if GlobalStateManager.<state_type>["key"]["nested"] <operator> <value> -> <marker_name>`

```
if GlobalStateManager.runtime_state["tutorial"]["complete"] == true -> already_done
if GlobalStateManager.persistent_data["statistics"]["high_scores"]["game1"] > 100 -> high_score_path
if GlobalStateManager.runtime_state["player"]["health"] <= 0 -> game_over
if GlobalStateManager.persistent_data["settings"]["difficulty"] >= 2 -> hard_mode
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

**State Types:**
- `runtime_state` - temporary state (not saved between sessions)
- `persistent_data` - saved state (preserved on load)

**Notes:**
- State paths use GlobalStateManager syntax with nested dictionary access
- If condition is false, execution continues to the next line
- If condition is true, execution jumps to the marker
- Missing keys return `null` and are treated as false
- Supports arbitrary nesting levels: `["a"]["b"]["c"]["d"]`

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

The DSL interpreter uses GlobalStateManager directly for all state access. No configuration needed - GlobalStateManager is a global autoload and is always available.

**Example state setup in your frontend:**

```gdscript
# Set runtime state (temporary)
GlobalStateManager.runtime_state["tutorial"] = {}
GlobalStateManager.runtime_state["tutorial"]["current_choice"] = 1
GlobalStateManager.runtime_state["tutorial"]["complete"] = false

# Set persistent data (saved)
GlobalStateManager.persistent_data["statistics"]["high_scores"]["game1"] = 250
GlobalStateManager.persistent_data["settings"]["difficulty"] = 2
```

Then reference these values in your DSL:

```
if GlobalStateManager.runtime_state["tutorial"]["complete"] == true -> done
cmd message tutorial Current choice: {GlobalStateManager.runtime_state["tutorial"]["current_choice"]}
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

This example demonstrates all DSL commands in a single tutorial sequence:

```
# tutorial.dsl - Complete tutorial with all command types

:start
cmd message tutorial_face smile
cmd message tutorial Welcome to the game!
cmd message tutorial_player [Press SPACE to continue]
wait_input space

cmd message tutorial_face neutral
cmd message tutorial Let's check your progress...
cmd message tutorial Your current choice: {GlobalStateManager.get_runtime("tutorial_choice")}
cmd message tutorial High score: {GlobalStateManager.get_persistent("high_score")}
signal on_tutorial_started
wait_time 1.5

# If statements check GlobalStateManager state and jump to markers if true
if GlobalStateManager.runtime_state["tutorial"]["complete"] == true -> already_done
if GlobalStateManager.persistent_data["statistics"]["high_scores"]["game1"] >= 100 -> high_score_path
if GlobalStateManager.runtime_state["player"]["lives"] != 3 -> lost_lives
if GlobalStateManager.persistent_data["settings"]["difficulty"] > 1 -> hard_mode

# If the condition is false, execution continues to next line
cmd message tutorial This is how you play...
cmd message tutorial_player [Press SPACE to continue]
wait_input any -> end

:high_score_path
cmd message tutorial_face excited
cmd message tutorial Wow, high score of {GlobalStateManager.get_persistent("high_score")}!
signal on_high_score
cmd message tutorial_player [Press any key to continue]
wait_input any -> end

:lost_lives
cmd message tutorial_face concerned
cmd message tutorial You lost a life! {GlobalStateManager.get_runtime("player_lives")} remaining...
signal on_lost_life
cmd message tutorial_player [Press any key to continue]
wait_input any -> end

:hard_mode
cmd message tutorial_face serious
cmd message tutorial Hard mode selected!
signal on_hard_mode
cmd message tutorial_player [Press any key to continue]
wait_input any -> end

:already_done
cmd message tutorial_face smile
cmd message tutorial You've already completed the tutorial!
signal on_tutorial_complete
cmd message tutorial_player [Press any key to continue]
wait_input any -> end

:end
cmd message tutorial_face neutral
cmd message tutorial Good luck out there!
cmd message tutorial_player
wait_time 2.0
```

**Key formatting notes:**

*If statements:*
- Syntax: `if GlobalStateManager.<state_type>["key"]["nested"] <operator> <value> -> <marker_name>`
- State types: `runtime_state` (temporary) or `persistent_data` (saved)
- Values can be: booleans (`true`/`false`), numbers (`100`, `1.5`), or strings (`"quoted"`)
- If the condition is **true**, jump to the marker
- If the condition is **false**, continue to the next line

*Variable substitution:*
- Syntax: `{GlobalStateManager.get_runtime("key")}` or `{GlobalStateManager.get_persistent("key")}`
- Values are substituted into command text before execution
- Missing keys return `null` and remain unchanged

*Wait input with jump:*
- Syntax: `wait_input <input_name> -> <marker_name>`
- When the specified input is received, jump to the marker
- Useful for creating branching paths based on player input
- `wait_input any -> marker` accepts any input before jumping

## Error Handling

The interpreter is designed to be crash-resistant:

- Unknown commands log a warning and are skipped
- Missing markers log an error but don't crash
- Missing state keys return `null` (override `_get_state_value` to customize)
- Malformed lines log a warning and are skipped
- Empty files or no instructions log an error on `start()`

Check the Godot output panel for warnings and errors during development.
