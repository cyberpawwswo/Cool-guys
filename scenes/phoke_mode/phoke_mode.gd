extends Control

func _ready() -> void:
	hide()
	_set_random_emoji()
	_set_random_audio()


func _on_timer_timeout() -> void:
	if randf() >= 0.5:
		return
	get_tree().paused = true
	_set_random_emoji()
	_set_random_audio()
	if $AudioStreamPlayer.stream == null:
		return
	show()
	_pause_other_audio(true)
	$AudioStreamPlayer.play()
	await $AudioStreamPlayer.finished
	if not is_inside_tree():
		return
	hide()
	_pause_other_audio(false)
	get_tree().paused = false

var arr_pause = []

func _pause_other_audio(paused: bool) -> void:
	if paused:
		for node in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
			if node is AudioStreamPlayer and node != $AudioStreamPlayer:
				if (node as AudioStreamPlayer).playing:
					arr_pause.append(node)
				(node as AudioStreamPlayer).stream_paused = paused
	else:
		for i in arr_pause:
			i.stream_paused = false
		arr_pause.clear()


func _set_random_emoji() -> void:
	var files := _resource_files("res://assets/troll_face/", ["jpg", "jpeg", "png", ".webp"])
	if files.is_empty():
		return
	$TextureRect2.texture = load("res://assets/troll_face/" + files[randi_range(0, files.size() - 1)])


func _set_random_audio() -> void:
	var files := _resource_files("res://assets/audio/phonk/", ["mp3", "ogg", "wav"])
	if files.is_empty():
		return
	$AudioStreamPlayer.stream = load("res://assets/audio/phonk/" + files[randi_range(0, files.size() - 1)])


func _resource_files(directory: String, extensions: Array[String]) -> Array[String]:
	var files: Array[String] = []
	for file in DirAccess.get_files_at(directory):
		if file.get_extension().to_lower() in extensions:
			files.append(file)
	return files
