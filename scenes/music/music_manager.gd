extends Node

const MUSIC_PATH := "res://assets/audio/music/brainrot_rap.mp3"
const MAX_LOAD_RETRIES := 10

var _player: AudioStreamPlayer
var _load_retries := 0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.volume_db = -8.0
	add_child(_player)
	_try_load_music()


func _try_load_music() -> void:
	var stream := load(MUSIC_PATH)
	if stream == null:
		_load_retries += 1
		if _load_retries <= MAX_LOAD_RETRIES:
			get_tree().create_timer(0.5).timeout.connect(_try_load_music)
		else:
			push_warning("Не удалось загрузить фоновую музыку: " + MUSIC_PATH)
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_player.stream = stream
	_player.play()
