extends Node

const MUSIC_FOLDER: String = "res://Working/Music/"

# Maps filename (without extension) -> full resource path
var _music_paths: Dictionary = {}

# Cache of loaded AudioStreams (lazy loaded on first play)
var _music_cache: Dictionary = {}

var _audio_player: AudioStreamPlayer
var _initialized: bool = false

var debug_mode: bool = true && OS.is_debug_build()


func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	add_child(_audio_player)
	_scan_music_folder()


func _process(_delta: float) -> void:
	if debug_mode:
		if Input.is_key_pressed(Key.KEY_0):
			CommandInterface.execute_text_command("play song3.mp3")


func _scan_music_folder() -> void:
	_music_paths.clear()
	_scan_directory(MUSIC_FOLDER)
	_initialized = true
	print("[Music] Scanned %d songs" % _music_paths.size())


func _scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		printerr("[Music] Cannot open directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_directory(path.path_join(file_name))
		else:
			var lower_name := file_name.to_lower()
			if lower_name.ends_with(".wav") or lower_name.ends_with(".ogg") or lower_name.ends_with(".mp3"):
				var full_path := path.path_join(file_name)
				var key := file_name.get_basename().to_lower()

				if not _music_paths.has(key):
					_music_paths[key] = full_path
				else:
					var parent := path.get_file()
					var alt_key := (parent + "/" + key).to_lower()
					_music_paths[alt_key] = full_path

		file_name = dir.get_next()

	dir.list_dir_end()


func play_song(song_filename: String) -> void:
	if not _initialized:
		printerr("[Music] Not initialized yet")
		return

	var stream := _get_stream(song_filename)
	if stream == null:
		printerr("[Music] Song not found: %s" % song_filename)
		return

	_audio_player.stream = stream
	_audio_player.play()


func _get_stream(song_name: String) -> AudioStream:
	var search_key := song_name.to_lower()

	# Remove extension if provided
	if search_key.ends_with(".wav") or search_key.ends_with(".ogg") or search_key.ends_with(".mp3"):
		search_key = search_key.get_basename()

	# Check cache first
	if _music_cache.has(search_key):
		return _music_cache[search_key]

	# Find the path - try exact match first
	var path: String = ""
	if _music_paths.has(search_key):
		path = _music_paths[search_key]
	else:
		# Try partial match
		for key in _music_paths.keys():
			if key.contains(search_key) or search_key.contains(key):
				path = _music_paths[key]
				break

	if path.is_empty():
		return null

	# Load and cache
	var stream := load(path) as AudioStream
	if stream:
		_music_cache[search_key] = stream

	return stream


func _get_songs_in_playlist(playlist: String) -> Array[String]:
	var songs: Array[String] = []
	var playlist_lower := playlist.to_lower()

	for key in _music_paths.keys():
		var path: String = _music_paths[key]
		if path.to_lower().contains(playlist_lower):
			songs.append(key)

	return songs


func play_random(playlist: String = "") -> void:
	if not _initialized:
		printerr("[Music] Not initialized yet")
		return

	var available_songs: Array[String] = []

	if playlist.is_empty():
		available_songs.assign(_music_paths.keys())
	else:
		available_songs = _get_songs_in_playlist(playlist)

	if available_songs.size() > 0:
		var random_song := available_songs[randi() % available_songs.size()]
		play_song(random_song)
	else:
		print("[Music] No songs found" + (" in playlist: " + playlist if not playlist.is_empty() else ""))


func stop() -> void:
	_audio_player.stop()


func is_playing() -> bool:
	return _audio_player.playing


func get_available_songs() -> Array:
	return _music_paths.keys()


func clear_cache() -> void:
	_music_cache.clear()


func rescan() -> void:
	clear_cache()
	_scan_music_folder()
