# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.5 online multiplayer game project using the GL Compatibility renderer. The project is in early stages with minimal content scaffolding.

## Development Commands

### Opening the Project

```bash
# Open the project in Godot 4.5 editor
godot project.godot
```

### Running the Game

```bash
# Run the game in debug mode from the editor
# Use Play button in editor or press F5
```

```bash
# Run the game from command line
godot --path . --main-pack
```

### Exporting

```bash
# Export the game (requires export templates)
godot --path . --export-debug
godot --path . --export-release
```

## Project Structure

- **project.godot** - Main project configuration file. Contains all project settings, autoloads, and feature flags.
- **icon.svg** - Default project icon (can be replaced)
- **scenes/** - Directory for scene files (currently empty, will contain .tscn files)
- **scripts/** - Directory for GDScript files (to be created)

## Architecture Notes

### Godot 4.5 Specifics

- Uses GDScript as the primary scripting language
- Scenes are the fundamental building blocks; they combine nodes into reusable components
- Node-based architecture: all game objects inherit from Node or its variants (Node2D, Node3D, Control, etc.)
- Use `@tool` scripts for editor-only functionality
- Use `class_name` to make scripts available globally without imports

### Multiplayer Game Considerations

- Consider using MultiplayerSynchronizer for network state synchronization
- Use MultiplayerSpawner for spawning network objects
- Implement peer authority checks before allowing state changes
- Use authority property to determine ownership of network objects

## Code Style

- Follow Godot GDScript conventions (snake_case for variables/functions, PascalCase for classes)
- Use type hints in function signatures for clarity
- Use constants (ALL_CAPS) for non-changing values
- Leverage Godot's signal system for decoupled communication between nodes

## Testing and Debugging

### Play Testing

In the Godot editor:
- Press F5 to run the current scene
- Press F8 to run the main scene
- Use debugger panel to inspect variables and set breakpoints

### Debugging

- Add breakpoints in the editor or via `breakpoint` statements in code
- Use `print()` for logging
- Use `get_tree().reload_current_scene()` to reload during development
- Check Output panel for runtime errors and warnings

## File Naming Conventions

- Scenes: `scene_name.tscn`
- Scripts: `script_name.gd`
- Resources: `resource_name.tres` or `resource_name.res`
- Shaders: `shader_name.gdshader`

## Configuration Files

- **.editorconfig** - Editor settings (UTF-8 encoding)
- **.gitattributes** - Git configuration for line endings (LF)
- **.gitignore** - Ignores .godot/ cache and android/ export directories

## Important Notes

- The `.godot/` directory is Godot's internal cache and should never be committed to git
- Always test on target platforms before releasing (desktop, web, mobile)
- For online multiplayer, plan networking architecture early (server authoritative vs peer-to-peer)
