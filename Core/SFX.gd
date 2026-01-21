extends Node

const SFX_FOLDER: String = "res://Working/SFX/"
const MAX_PLAYERS: int = 8  # Maximum concurrent sounds

# Maps filename (without extension) -> full resource path
var _sfx_paths: Dictionary = {}

# Cache of loaded AudioStreams (lazy loaded on first play)
var _sfx_cache: Dictionary = {}

# Pool of audio players for concurrent playback
var _audio_players: Array[AudioStreamPlayer] = []
var _current_player_index: int = 0

var _initialized: bool = false


func _ready() -> void:
	_setup_audio_players()
	_scan_sfx_folder()


func _setup_audio_players() -> void:
	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_audio_players.append(player)


func _scan_sfx_folder() -> void:
	_sfx_paths.clear()
	_scan_directory(SFX_FOLDER)
	_initialized = true
	print("[SFX] Scanned %d sound effects" % _sfx_paths.size())


func _scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		printerr("[SFX] Cannot open directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_directory(path.path_join(file_name))
		else:
			# Check for audio file extensions
			var lower_name := file_name.to_lower()
			if lower_name.ends_with(".wav") or lower_name.ends_with(".ogg") or lower_name.ends_with(".mp3"):
				var full_path := path.path_join(file_name)
				var key := file_name.get_basename().to_lower()

				# Handle duplicate names by storing first found (or could use full path)
				if not _sfx_paths.has(key):
					_sfx_paths[key] = full_path
				else:
					# Store with parent folder prefix for disambiguation
					var parent := path.get_file()
					var alt_key := (parent + "/" + key).to_lower()
					_sfx_paths[alt_key] = full_path

		file_name = dir.get_next()

	dir.list_dir_end()


func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not _initialized:
		printerr("[SFX] Not initialized yet")
		return

	var stream := _get_stream(sfx_name)
	if stream == null:
		printerr("[SFX] Sound not found: %s" % sfx_name)
		return

	var player := _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _get_stream(sfx_name: String) -> AudioStream:
	var search_key := sfx_name.to_lower()

	# Remove extension if provided
	if search_key.ends_with(".wav") or search_key.ends_with(".ogg") or search_key.ends_with(".mp3"):
		search_key = search_key.get_basename()

	# Check cache first
	if _sfx_cache.has(search_key):
		return _sfx_cache[search_key]

	# Find the path - try exact match first
	var path: String = ""
	if _sfx_paths.has(search_key):
		path = _sfx_paths[search_key]
	else:
		# Try partial match (filename contains search term)
		for key in _sfx_paths.keys():
			if key.contains(search_key) or search_key.contains(key):
				path = _sfx_paths[key]
				break

	if path.is_empty():
		return null

	# Load and cache
	var stream := load(path) as AudioStream
	if stream:
		_sfx_cache[search_key] = stream

	return stream


func _get_available_player() -> AudioStreamPlayer:
	# Find a player that's not playing, or use round-robin
	for player in _audio_players:
		if not player.playing:
			return player

	# All playing, use round-robin to steal oldest
	var player := _audio_players[_current_player_index]
	_current_player_index = (_current_player_index + 1) % MAX_PLAYERS
	return player


# Preload specific sounds into cache (optional, for performance-critical sounds)
func preload_sfx(sfx_names: Array[String]) -> void:
	for sfx_name in sfx_names:
		_get_stream(sfx_name)


# Get list of all available sound effect names
func get_available_sfx() -> Array:
	return _sfx_paths.keys()


# Clear the cache (useful if SFX folder contents change at runtime)
func clear_cache() -> void:
	_sfx_cache.clear()


# Rescan the SFX folder
func rescan() -> void:
	clear_cache()
	_scan_sfx_folder()


# Stop all currently playing sounds
func stop_all() -> void:
	for player in _audio_players:
		player.stop()
