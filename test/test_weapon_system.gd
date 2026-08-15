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
	if manager.get_weapon_count() != 3:
		_fail("Expected 3 weapons, got %d" % manager.get_weapon_count())
		return
	if manager._fire_audio_players.size() != 3 or manager._reload_audio_players.size() != 3:
		_fail("Expected audio players for all 3 weapon slots")
		return
	for index in 2:
		if manager._fire_audio_players[index].max_polyphony < 4:
			_fail("Weapon %d fire sound cannot overlap" % index)
			return

	var expected_names := ["Boomstick", "Beretta", "Leg Kick"]
	for index in manager.get_weapon_count():
		manager.select_weapon(index, true)
		if manager.get_current_weapon_name() != expected_names[index]:
			_fail("Unexpected weapon in slot %d" % index)
			return
		if not manager.play_attack():
			_fail("Weapon %d has no playable attack animation" % index)
			return
		if index < 2 and not manager._fire_audio_players[index].playing:
			_fail("Weapon %d fire sound did not play" % index)
			return
		if index == 2 and manager._fire_audio_players[index].stream != null:
			_fail("Leg Kick unexpectedly has a fire sound")
			return
		if index == 1 and manager._animation_players[index].is_playing():
			_fail("Beretta started the full reload animation after firing")
			return

	manager.select_weapon(0, true)
	manager.reload_current_weapon()
	if not manager._reload_audio_players[0].playing:
		_fail("Boomstick shell reload sound did not play")
		return

	manager.select_weapon(1, true)
	var pistol_slide: Node3D = manager._procedural_slides[1]
	var slide_rest_position: Vector3 = manager._procedural_slide_positions[1]
	if not manager.play_attack():
		_fail("Beretta procedural fire failed")
		return
	manager._process(0.03)
	if pistol_slide.position.is_equal_approx(slide_rest_position):
		_fail("Beretta slide did not move after firing")
		return
	manager._process(0.15)
	if pistol_slide.position.distance_to(slide_rest_position) > 0.001:
		_fail("Beretta slide did not return after firing")
		return

	manager.select_weapon(1, true)
	var pistol_skeletons: Array[Node] = manager._weapon_models[1].find_children(
		"*", "Skeleton3D", true, false
	)
	if pistol_skeletons.is_empty():
		_fail("Beretta skeleton is missing")
		return
	var pistol_skeleton := pistol_skeletons[0] as Skeleton3D
	var pistol_rest_pose: Array[Transform3D] = []
	for bone_index in pistol_skeleton.get_bone_count():
		pistol_rest_pose.append(pistol_skeleton.get_bone_pose(bone_index))
	manager.reload_current_weapon()
	if not manager._reload_audio_players[1].playing:
		_fail("Beretta reload sound did not play")
		return
	var pistol_player: AnimationPlayer = manager._animation_players[1]
	if not pistol_player.active or not pistol_player.is_playing():
		_fail("Beretta reload section did not start")
		return
	pistol_player.advance(0.001)
	var reload_position := pistol_player.get_current_animation_position()
	if reload_position < manager.PISTOL_RELOAD_START - 0.01:
		_fail("Beretta reload started before the reload section")
		return
	pistol_player.advance(2.0)
	manager._process(0.01)
	if pistol_player.is_playing() or pistol_player.active:
		_fail("Beretta reload section did not finish cleanly")
		return
	for bone_index in pistol_skeleton.get_bone_count():
		if not pistol_skeleton.get_bone_pose(bone_index).is_equal_approx(
			pistol_rest_pose[bone_index]
		):
			_fail("Beretta pose changed after reload")
			return

	manager.select_weapon(2, true)
	var wheel_event := InputEventMouseButton.new()
	wheel_event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_event.pressed = true
	player._input(wheel_event)
	if manager.get_current_weapon_name() != "Boomstick":
		_fail("Mouse wheel input was not forwarded to the viewmodel")
		return

	print("WEAPON SYSTEM TEST PASSED: 3 weapons loaded and switched")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
