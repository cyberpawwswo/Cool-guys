extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var left_events := InputMap.action_get_events("attack")
	var right_events := InputMap.action_get_events("web_swing")
	if (
		left_events.is_empty()
		or not left_events[0] is InputEventMouseButton
		or left_events[0].button_index != MOUSE_BUTTON_LEFT
		or right_events.is_empty()
		or not right_events[0] is InputEventMouseButton
		or right_events[0].button_index != MOUSE_BUTTON_RIGHT
	):
		_fail("left and right web inputs are not mapped to LMB and RMB")
		return

	var world := Node3D.new()
	root.add_child(world)
	current_scene = world

	var wall := StaticBody3D.new()
	wall.position = Vector3(0.0, 12.0, -25.0)
	var wall_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(24.0, 24.0, 1.0)
	wall_shape.shape = box
	wall.add_child(wall_shape)
	world.add_child(wall)

	var player := PLAYER_SCENE.instantiate()
	world.add_child(player)
	for frame in range(3):
		await physics_frame
	var manager = player.weapon_manager
	manager.select_weapon(3, true)
	if not manager.is_web_shooter_selected():
		_fail("web shooters are not available as weapon slot 4")
		return
	var left_origin_uv: Vector2 = manager.get_web_origin_viewport_uv(player.WEB_LEFT)
	var right_origin_uv: Vector2 = manager.get_web_origin_viewport_uv(player.WEB_RIGHT)
	if (
		not left_origin_uv.is_finite()
		or not right_origin_uv.is_finite()
		or left_origin_uv.x >= right_origin_uv.x
		or left_origin_uv.x < 0.0
		or right_origin_uv.x > 1.0
		or left_origin_uv.y < 0.0
		or left_origin_uv.y > 1.0
		or right_origin_uv.y < 0.0
		or right_origin_uv.y > 1.0
	):
		_fail("web origins are not attached to the left and right viewmodel emitters")
		return

	var left_hit: Dictionary = player._find_web_anchor(player.WEB_LEFT)
	var right_hit: Dictionary = player._find_web_anchor(player.WEB_RIGHT)
	if left_hit.is_empty() or right_hit.is_empty():
		_fail("both web shooters must find a valid building anchor")
		return
	player._attach_web(left_hit, player.WEB_LEFT)
	player._attach_web(right_hit, player.WEB_RIGHT)
	if (
		not player._web_states[player.WEB_LEFT]["active"]
		or not player._web_states[player.WEB_RIGHT]["active"]
		or not player._web_lines[player.WEB_LEFT].visible
		or not player._web_lines[player.WEB_RIGHT].visible
	):
		_fail("left and right webs did not attach independently")
		return
	if (
		player._web_states[player.WEB_LEFT]["rope_length"] <= 0.0
		or player._web_states[player.WEB_RIGHT]["rope_length"] <= 0.0
	):
		_fail("web rope lengths were not initialized")
		return

	player._update_web_visual(0.25)
	for side in 2:
		var web_mesh := player._web_lines[side].mesh as ImmediateMesh
		if player._web_lines[side].get_viewport() != manager.get_viewport():
			_fail("web ribbon is not rendered in the viewmodel viewport")
			return
		if web_mesh.get_surface_count() == 0:
			_fail("detailed web mesh was not generated")
			return
		if not player._web_lines[side].global_transform.is_finite():
			_fail("web mesh produced an invalid transform")
			return
	var root_viewport_size := Vector2(player.get_viewport().get_visible_rect().size)
	var anchor: Vector3 = player._web_states[player.WEB_LEFT]["anchor"]
	var anchor_uv: Vector2 = player.camera.unproject_position(anchor) / root_viewport_size
	var visual_target: Vector3 = manager.get_web_visual_target(anchor_uv, player.web_visual_depth)
	var viewmodel_camera: Camera3D = manager.get_viewmodel_camera()
	var viewmodel_size := Vector2(viewmodel_camera.get_viewport().get_visible_rect().size)
	var visual_target_uv := viewmodel_camera.unproject_position(visual_target) / viewmodel_size
	if visual_target_uv.distance_to(anchor_uv) > 0.001:
		_fail("viewmodel web target does not converge on the world anchor on screen")
		return
	var old_left_origin: Vector3 = player._web_lines[player.WEB_LEFT].global_position
	player.camera.position += Vector3(0.35, 0.18, -0.12)
	player.camera.rotation.y += 0.08
	manager.position += Vector3(0.09, -0.04, 0.0)
	player._update_web_visual(1.0 / 60.0)
	var expected_left_origin: Vector3 = player._get_web_hand_position(player.WEB_LEFT)
	if not player._web_lines[player.WEB_LEFT].global_position.is_equal_approx(expected_left_origin):
		_fail("web start did not follow the camera hand position")
		return
	if player._web_lines[player.WEB_LEFT].global_position.is_equal_approx(old_left_origin):
		_fail("web start remained stuck after camera movement")
		return

	player.velocity = Vector3(10.0, -3.0, -6.0)
	player._update_web_swing(Vector3.RIGHT, 1.0 / 60.0)
	if player.velocity.length() > player.web_max_speed + 0.01:
		_fail("web swing exceeded its configured speed limit")
		return
	player._release_web(player.WEB_LEFT)
	if (
		player._web_states[player.WEB_LEFT]["active"]
		or not player._web_states[player.WEB_RIGHT]["active"]
	):
		_fail("left web release incorrectly affected the right web")
		return
	var speed_before_release: float = player.velocity.length()
	player._release_all_webs(true)
	if player._has_active_web() or player._web_lines[player.WEB_RIGHT].visible:
		_fail("webs did not release cleanly")
		return
	if player.velocity.length() <= speed_before_release:
		_fail("boosted release did not preserve and add momentum")
		return

	print("WEB SHOOTER TEST PASSED")
	quit(0)


func _fail(message: String) -> void:
	push_error("WEB SHOOTER TEST FAILED: " + message)
	quit(1)
