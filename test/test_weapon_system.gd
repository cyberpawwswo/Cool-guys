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
	if (
		manager._fire_audio_players.size() != 3
		or manager._fire_tail_audio_players.size() != 3
		or manager._reload_audio_players.size() != 3
	):
		_fail("Expected audio players for all 3 weapon slots")
		return
	if (
		manager._muzzle_effect_roots.size() != 3
		or manager._muzzle_anchors.size() != 3
		or manager._muzzle_flash_roots.size() != 3
		or manager._muzzle_smoke_particles.size() != 3
		or manager._muzzle_spark_particles.size() != 3
		or manager._muzzle_gas_particles.size() != 3
	):
		_fail("Expected complete muzzle effect slots for all weapons")
		return
	for index in 2:
		if manager._fire_audio_players[index].max_polyphony < 4:
			_fail("Weapon %d fire sound cannot overlap" % index)
			return
		if manager._fire_audio_players[index].volume_db <= 0.0:
			_fail("Weapon %d fire sound is not boosted" % index)
			return
	if manager.ammo_label == null or manager.ammo_label.text != "6 / 24":
		_fail("Ammo HUD did not initialize")
		return

	var expected_names := ["Boomstick", "Beretta", "Leg Kick"]
	var starting_magazines := [6, 15, 0]
	var starting_reserves := [24, 60, 0]
	for index in manager.get_weapon_count():
		manager.select_weapon(index, true)
		if manager.get_current_weapon_name() != expected_names[index]:
			_fail("Unexpected weapon in slot %d" % index)
			return
		if not manager.play_attack():
			_fail("Weapon %d has no playable attack animation" % index)
			return
		var expected_ammo: int = starting_magazines[index] - (1 if index < 2 else 0)
		if manager.get_current_ammo() != expected_ammo:
			_fail("Weapon %d did not consume exactly one round" % index)
			return
		if manager.get_current_reserve_ammo() != starting_reserves[index]:
			_fail("Weapon %d consumed reserve ammo while firing" % index)
			return
		if index < 2 and not manager._fire_audio_players[index].playing:
			_fail("Weapon %d fire sound did not play" % index)
			return
		if index < 2 and not manager._fire_tail_audio_players[index].playing:
			_fail("Weapon %d low fire tail did not play" % index)
			return
		if index < 2 and (
			manager._muzzle_flash_roots[index] == null
			or not manager._muzzle_flash_roots[index].visible
			or manager._muzzle_flash_lights[index].light_energy <= 0.0
			or not manager._muzzle_smoke_particles[index].emitting
			or not manager._muzzle_spark_particles[index].emitting
			or not manager._muzzle_gas_particles[index].emitting
		):
			_fail("Weapon %d muzzle effects did not trigger" % index)
			return
		if index < 2 and not manager._muzzle_effect_roots[index].global_position.is_equal_approx(
			manager._muzzle_anchors[index].global_position
		):
			_fail("Weapon %d muzzle effects did not follow the barrel" % index)
			return
		if index == 2 and manager._fire_audio_players[index].stream != null:
			_fail("Leg Kick unexpectedly has a fire sound")
			return
		if index == 2 and manager.ammo_label.visible:
			_fail("Leg Kick unexpectedly shows the ammo HUD")
			return
		if index == 2 and (
			manager._muzzle_effect_roots[index] != null
			or manager._muzzle_anchors[index] != null
			or manager._muzzle_flash_roots[index] != null
			or manager._muzzle_smoke_particles[index] != null
			or manager._muzzle_spark_particles[index] != null
			or manager._muzzle_gas_particles[index] != null
		):
			_fail("Leg Kick unexpectedly has muzzle effects")
			return
		if index == 1 and manager._animation_players[index].is_playing():
			_fail("Beretta started the full reload animation after firing")
			return
	if (
		player._weapon_recoil_pitch <= 0.0
		or player._weapon_recoil_back <= 0.0
		or player._weapon_recoil_kick_time <= 0.0
		or player._shot_flash_alpha <= 0.0
		or player._shot_concussion_strength <= 0.0
		or player._shot_concussion_material == null
	):
		_fail("Weapon fire did not trigger layered camera recoil and screen effects")
		return
	if (
		manager._recoil_position_velocity == Vector3.ZERO
		or manager._recoil_rotation_velocity == Vector3.ZERO
	):
		_fail("Weapon fire did not trigger spring recoil")
		return
	manager._process(0.2)
	for index in 2:
		if manager._muzzle_flash_roots[index].visible:
			_fail("Weapon %d muzzle flash did not finish" % index)
			return
	for frame in 120:
		manager._process(1.0 / 60.0)
	if (
		manager._recoil_position.length() > 0.001
		or manager._recoil_rotation.length() > 0.001
		or manager._recoil_position_velocity.length() > 0.001
		or manager._recoil_rotation_velocity.length() > 0.001
	):
		_fail("Spring recoil did not settle back to rest")
		return

	manager.select_weapon(0, true)
	manager.reload_current_weapon()
	if not manager._reload_audio_players[0].playing:
		_fail("Boomstick shell reload sound did not play")
		return
	if not manager.is_reloading() or manager.get_current_ammo() != 5:
		_fail("Boomstick ammo changed before reload finished")
		return
	var shotgun_player: AnimationPlayer = manager._animation_players[0]
	shotgun_player.advance(2.0)
	manager._process(0.01)
	if manager.is_reloading():
		_fail("Boomstick reload did not finish")
		return
	if manager.get_current_ammo() != 6 or manager.get_current_reserve_ammo() != 23:
		_fail("Boomstick did not load exactly one shell")
		return
	if manager.ammo_label.text != "6 / 23":
		_fail("Boomstick ammo HUD did not update")
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
	if not manager.is_reloading() or manager.get_current_ammo() != 13:
		_fail("Beretta ammo changed before reload finished")
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
	if manager.is_reloading():
		_fail("Beretta reload state did not finish")
		return
	if manager.get_current_ammo() != 15 or manager.get_current_reserve_ammo() != 58:
		_fail("Beretta magazine was not filled from reserve")
		return
	if manager.ammo_label.text != "15 / 58":
		_fail("Beretta ammo HUD did not update")
		return
	for bone_index in pistol_skeleton.get_bone_count():
		if not pistol_skeleton.get_bone_pose(bone_index).is_equal_approx(
			pistol_rest_pose[bone_index]
		):
			_fail("Beretta pose changed after reload")
			return

	manager._ammo_in_magazine[1] = 1
	manager._attack_cooldown_left = 0.0
	if not manager.play_attack():
		_fail("Beretta could not fire its last round")
		return
	manager._attack_cooldown_left = 0.0
	if manager.play_attack() or manager.get_current_ammo() != 0:
		_fail("Beretta fired with an empty magazine")
		return
	manager.reload_current_weapon()
	if not manager.is_reloading():
		_fail("Beretta could not reload from empty")
		return
	manager.select_weapon(2)
	if manager.is_reloading() or manager._ammo_in_magazine[1] != 0:
		_fail("Switching weapons did not cancel Beretta reload")
		return
	if manager._ammo_reserve[1] != 58:
		_fail("Cancelled Beretta reload consumed reserve ammo")
		return

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
