extends SceneTree


func _initialize() -> void:
	_run_test.call_deferred()


func _run_test() -> void:
	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	if player_scene == null:
		_fail("Player scene could not be loaded")
		return

	var player := player_scene.instantiate()
	root.add_child(player)
	await process_frame

	var manager := player.get_node_or_null(
		"Control/ViewmodelContainer/ViewmodelViewport/ViewmodelCamera/WeaponManager"
	)
	if manager == null:
		_fail("WeaponManager is missing")
		return
	if manager.get_weapon_count() != 6:
		_fail("Expected 6 weapons, got %d" % manager.get_weapon_count())
		return

	for index in manager.get_weapon_count():
		manager.select_weapon(index, true)
		if manager.get_current_weapon_name().is_empty():
			_fail("Weapon %d has no display name" % index)
			return
		if not manager.play_attack():
			_fail("Weapon %d has no playable attack animation" % index)
			return

	var wheel_event := InputEventMouseButton.new()
	wheel_event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_event.pressed = true
	player._input(wheel_event)
	if manager.get_current_weapon_name() != "Boomstick":
		_fail("Mouse wheel input was not forwarded to the viewmodel")
		return

	print("WEAPON SYSTEM TEST PASSED: 6 weapons loaded and switched")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
