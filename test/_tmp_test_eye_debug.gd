extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Control = load("res://scenes/tuan_sahur/eye_debug.tscn").instantiate()
	root.add_child(scene)
	for i in 5:
		await process_frame
	scene.size = Vector2(1200, 800)
	await process_frame
	await process_frame

	var tr: TextureRect = null
	for child in scene.find_children("*", "TextureRect", true, false):
		tr = child
		break
	if tr == null:
		push_error("no TextureRect")
		quit(1)
		return
	print("TextureRect size=%s texture=%s" % [tr.size, tr.texture])
	if tr.texture == null or tr.size.x <= 1.0:
		push_error("image not shown or zero-size")
		quit(1)
		return

	var overlay: Control = null
	for child in scene.find_children("*", "Control", true, false):
		if child.mouse_filter == Control.MOUSE_FILTER_STOP:
			overlay = child
			break
	if overlay == null:
		push_error("no overlay")
		quit(1)
		return
	print("overlay size=%s" % overlay.size)

	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = overlay.size * Vector2(0.3, 0.3)
	overlay._on_overlay_input(ev)
	ev.position = overlay.size * Vector2(0.7, 0.35)
	overlay._on_overlay_input(ev)

	print("eyes after 2 clicks: ", scene._eyes)
	if scene._eyes[0].x > 0.4 and scene._eyes[0].x < 0.2:
		push_error("eye1 not set")
		quit(1)
		return
	scene._save_eyes()
	var cfg := ConfigFile.new()
	if cfg.load("res://scenes/tuan_sahur/eye_positions.cfg") != OK:
		push_error("cfg not saved")
		quit(1)
		return
	var saved_x := float(cfg.get_value("eyes", "eye2_x", -1.0))
	print("saved eye2_x=%.3f (expected ~0.7)" % saved_x)
	if absf(saved_x - 0.7) > 0.05:
		push_error("saved value mismatch")
		quit(1)
		return
	print("EYE DEBUG LOGIC OK")
	quit(0)
