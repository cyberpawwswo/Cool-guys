extends Node

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var play := get_tree().current_scene.get_node_or_null("CenterContainer/VBoxContainer/PlayButton")
	if play == null:
		print("AUTOPRESS: no PlayButton")
		get_tree().quit(1)
		return
	play.emit_signal("pressed")
	await get_tree().create_timer(2.0).timeout
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		print("AUTOPRESS: no player")
		get_tree().quit(1)
		return
	print("AUTOPRESS: READY_FOR_ESC")
	for i in range(100):
		await get_tree().create_timer(0.2).timeout
		if player.pause_menu.visible:
			print("AUTOPRESS: RESULT OPEN (menu visible, paused=", get_tree().paused, ")")
			get_tree().quit(0)
			return
	print("AUTOPRESS: RESULT NOT_OPEN")
	get_tree().quit(1)
