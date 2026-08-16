extends SceneTree

const LEVEL_SCENE := preload("res://scenes/levels/test_level/test_level.tscn")


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	current_scene = level
	for frame in range(10):
		await physics_frame
	var player := level.get_node_or_null("Player")
	if player == null:
		print("PAUSE DEBUG: no player node")
		quit(1)
		return
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	print("PAUSE DEBUG: pushing input via root.push_input")
	root.push_input(esc)
	await physics_frame
	await process_frame
	print("PAUSE DEBUG: after push_input paused=", paused, " visible=", player.pause_menu.visible)
	if player.pause_menu.visible:
		print("PAUSE DEBUG: MENU OPENS VIA PUSH INPUT")
	else:
		print("PAUSE DEBUG: MENU DOES NOT OPEN VIA PUSH INPUT")
	quit(0)
