extends Node

const MUSIC_FOLDER: String = "res://Working/Music/"

# Dictionary of preloaded music files
# Key: full filepath, Value: preloaded AudioStream
var music_library: Dictionary = {
	"Working/Music/Development/song1.mp3": preload("res://Working/Music/Development/song1.mp3"),
	"Working/Music/Development/song2.mp3": preload("res://Working/Music/Development/song2.mp3"),
	"Working/Music/Development/song3.mp3": preload("res://Working/Music/Development/song3.mp3"),
}

var debug_mode : bool = true && OS.is_debug_build()
@onready var _my_audio_player : AudioStreamPlayer = AudioStreamPlayer.new()


func _ready() -> void:

	get_tree().root.call_deferred("add_child", _my_audio_player)

	await get_tree().process_frame

	# Example: play the first song
	play_random()


func _process(_delta: float) -> void:
	if debug_mode:
		if Input.is_key_pressed(Key.KEY_0):
			CommandInterface.execute_text_command("play song3.mp3")
	pass




func play_song(song_filename: String) -> void:
	for key in music_library.keys():
		if key.ends_with(song_filename):
			_my_audio_player.stream = music_library[key]
			_my_audio_player.play()
			return

	printerr("Song not found in library: " + song_filename)


func play_random(playlist: String = "") -> void:
	var available_songs: Array = []

	# Filter songs by playlist folder if specified
	if playlist.is_empty():
		available_songs = music_library.values()
	else:
		for key in music_library.keys():
			if key.contains("Working/Music/" + playlist):
				available_songs.append(music_library[key])

	# Play a random song if any are available
	if available_songs.size() > 0:
		var random_song = available_songs[randi() % available_songs.size()]
		_my_audio_player.stream = random_song
		_my_audio_player.play()
	else:
		print("No songs found" + (" in playlist: " + playlist if not playlist.is_empty() else ""))
