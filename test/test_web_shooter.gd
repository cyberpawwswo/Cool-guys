extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
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

	var hit: Dictionary = player._find_web_anchor()
	if hit.is_empty():
		_fail("web shooter did not find a valid building anchor")
		return
	player._attach_web(hit)
	if not player._web_active or not player._web_line.visible:
		_fail("web did not attach or show its line")
		return
	if player._web_rope_length <= 0.0:
		_fail("web rope length was not initialized")
		return

	player.velocity = Vector3(10.0, -3.0, -6.0)
	player._update_web_swing(Vector3.RIGHT, 1.0 / 60.0)
	if player.velocity.length() > player.web_max_speed + 0.01:
		_fail("web swing exceeded its configured speed limit")
		return
	var speed_before_release: float = player.velocity.length()
	player._release_web(true)
	if player._web_active or player._web_line.visible:
		_fail("web did not release cleanly")
		return
	if player.velocity.length() <= speed_before_release:
		_fail("boosted release did not preserve and add momentum")
		return

	print("WEB SHOOTER TEST PASSED")
	quit(0)


func _fail(message: String) -> void:
	push_error("WEB SHOOTER TEST FAILED: " + message)
	quit(1)
