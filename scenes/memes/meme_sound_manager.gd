extends Node

## Случайные мемные звуки: играют непрерывно, звук за звуком.
## Когда предыдущий закончился + маленькая пауза, играется следующий случайный.
## Кидай свои mp3/wav/ogg в SOUNDS_FOLDER — подхватятся автоматически.

const SOUNDS_FOLDER := "res://assets/audio/memes/"
const POOL_SIZE := 4
const MIN_GAP := 0.1
const MAX_GAP := 0.5
const RESCAN_INTERVAL := 3.0

var _sounds: Array[AudioStream] = []
var _players: Array[AudioStreamPlayer] = []
var _gap_timer := 0.4
var _rescan_timer := 0.0


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "MemePlayer%d" % (i + 1)
		player.volume_db = 3.0
		add_child(player)
		_players.append(player)
	_scan_sounds()


func _process(delta: float) -> void:
	_rescan_timer -= delta
	if _rescan_timer <= 0.0:
		_rescan_timer = RESCAN_INTERVAL
		_scan_sounds()
	if _sounds.is_empty():
		return
	if _any_playing():
		return
	_gap_timer -= delta
	if _gap_timer <= 0.0:
		_play_random()
		_gap_timer = randf_range(MIN_GAP, MAX_GAP)


func _any_playing() -> bool:
	for player in _players:
		if player.playing:
			return true
	return false


func _scan_sounds() -> void:
	_sounds.clear()
	var dir := DirAccess.open(SOUNDS_FOLDER)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.get_extension() in ["mp3", "wav", "ogg"]:
			var stream := load(SOUNDS_FOLDER + file)
			if stream is AudioStream and stream.get_length() > 0.0:
				_sounds.append(stream)
		file = dir.get_next()
	dir.list_dir_end()


func _play_random() -> void:
	if _sounds.is_empty():
		return
	var stream := _sounds[randi() % _sounds.size()]
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	_players[0].stream = stream
	_players[0].play()
