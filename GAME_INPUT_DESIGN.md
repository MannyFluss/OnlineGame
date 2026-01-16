# Game Input Management Design

## Decision: Option 1 - Isolated Input Handlers

### Overview
Games and the terminal operate with completely separate input systems. When a game is active, the global input system is disabled and the game handles raw input events directly.

### How It Works

**Terminal Mode:**
- `GlobalInput` processes raw `InputEvent` objects
- Parses input into commands (text-based, signal-based)
- Emits `command_entered` and `command_edited` signals
- `CommandInterface` listens and executes commands

**Game Mode:**
- `GlobalInput._input()` is disabled (input doesn't route through GlobalInput)
- Game node implements its own `_input(event: InputEvent)` function
- Game handles raw keyboard/mouse events directly
- Can handle real-time input, keyholds, analog input, etc.

### Implementation Pattern

```gdscript
# Control flag in GlobalInput
var input_enabled: bool = true

func _input(event: InputEvent) -> void:
    if not input_enabled:  # Game is active
        return
    # Otherwise handle terminal input normally...
```

When launching a game:
1. Set `GlobalInput.input_enabled = false`
2. Instantiate game scene
3. Game handles all input via its own `_input()` implementation

When exiting a game:
1. Set `GlobalInput.input_enabled = true`
2. Terminal input resumes

### Advantages
- **Clean separation** - No coupling between terminal and game input paradigms
- **Flexible** - Each game can implement input however it needs
- **Scalable** - Works for many different game types
- **Simple** - Just toggle one boolean flag

### Optional: GameBase Class
Create a reusable base for all games:
```gdscript
extends Node
class_name GameBase

func _input(event: InputEvent) -> void:
    # Override in subclasses
    pass

func on_game_exit() -> void:
    # Save state, cleanup
    pass
```

### State Preservation
When transitioning to/from games:
- Save terminal state (current directory, visible output)
- Restore terminal state on game exit
- Use `GameManager` singleton to handle state stack
