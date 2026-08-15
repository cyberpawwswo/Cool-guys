extends Node3D


signal weapon_changed(index: int, display_name: String)

@export_category("Viewmodel Motion")
@export var motion_smoothing := 19.0
@export var sway_position_amount := 0.00018
@export var sway_rotation_amount := 0.02
@export var movement_lag_amount := 0.0035
@export var walk_bob_amount := 0.006
@export var walk_bob_speed := 9.0
@export var equip_drop := 0.12

const WEAPON_DATA: Array[Dictionary] = [
	{
		"display_name": "Boomstick",
		"scene": preload("res://assets/weapons/shotgun/source/shotgunAnimated.fbx"),
		"attack_animations": [&"Armature|Fire"],
		"reload_animation": &"Armature|ReloadOne",
		"equip_animation": &"Armature|Weild",
		"idle_animation": StringName(),
		"cooldown": 0.65,
		"manual_scale": 0.95,
		"manual_position": Vector3(0.22, -0.58, -0.65),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"hide_when_idle": false,
	},
	{
		"display_name": "Beretta",
		"scene": preload("res://assets/weapons/pistol/source/arms@beretta.fbx"),
		"attack_animations": [&"CINEMA_4D_Main"],
		"reload_animation": StringName(),
		"equip_animation": StringName(),
		"idle_animation": StringName(),
		"cooldown": 0.35,
		"manual_scale": 1.35,
		"manual_position": Vector3(0.27, -0.5, -0.58),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"hide_when_idle": false,
	},
	{
		"display_name": "Leg Kick",
		"scene": preload("res://assets/weapons/legkick/source/legkick.fbx"),
		"attack_animations": [&"Armature|Kick1", &"Armature|Kick2"],
		"reload_animation": StringName(),
		"equip_animation": StringName(),
		"idle_animation": StringName(),
		"cooldown": 0.55,
		"manual_scale": 0.85,
		"manual_position": Vector3(0.12, -0.55, -0.72),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"hide_when_idle": true,
	},
]

@onready var weapon_label: Label = _get_player().get_node_or_null("Control/WeaponLabel")

var current_weapon_index := 0
var _weapon_slots: Array[Node3D] = []
var _weapon_models: Array[Node3D] = []
var _animation_players: Array[AnimationPlayer] = []
var _attack_cooldown_left := 0.0
var _attack_variant := 0
var _mouse_motion := Vector2.ZERO
var _bob_time := 0.0
var _equip_amount := 0.0
var _sprint_amount := 0.0
var _recoil_position := Vector3.ZERO
var _recoil_rotation := Vector3.ZERO


func _ready() -> void:
	for index in WEAPON_DATA.size():
		_create_weapon(index)
	select_weapon(0, true)


func _process(delta: float) -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	_update_viewmodel_motion(delta)

	var animation_player := _animation_players[current_weapon_index]
	if animation_player and not animation_player.is_playing():
		if WEAPON_DATA[current_weapon_index]["hide_when_idle"]:
			_weapon_models[current_weapon_index].visible = false
		else:
			_play_current_idle()


func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_motion += event.relative
		_mouse_motion.x = clampf(_mouse_motion.x, -55.0, 55.0)
		_mouse_motion.y = clampf(_mouse_motion.y, -40.0, 40.0)

	if event is InputEventKey and event.pressed and not event.echo:
		var number_index := _number_key_to_index(event.physical_keycode)
		if number_index >= 0:
			select_weapon(number_index)
			_get_player().get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_R:
			reload_current_weapon()
			_get_player().get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_weapon(current_weapon_index - 1)
			_get_player().get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_weapon(current_weapon_index + 1)
			_get_player().get_viewport().set_input_as_handled()


func select_weapon(index: int, instant := false) -> void:
	if _weapon_slots.is_empty():
		return

	var wrapped_index := wrapi(index, 0, _weapon_slots.size())
	if wrapped_index == current_weapon_index and not instant:
		return

	for slot_index in _weapon_slots.size():
		_weapon_slots[slot_index].visible = slot_index == wrapped_index
		var player := _animation_players[slot_index]
		if player and slot_index != wrapped_index:
			player.stop()

	current_weapon_index = wrapped_index
	_attack_cooldown_left = 0.0
	_attack_variant = 0
	_equip_amount = 1.0
	_recoil_position = Vector3.ZERO
	_recoil_rotation = Vector3.ZERO
	_weapon_models[current_weapon_index].visible = not WEAPON_DATA[current_weapon_index]["hide_when_idle"]
	_update_weapon_label()

	var equip_animation: StringName = WEAPON_DATA[current_weapon_index]["equip_animation"]
	if not _play_animation(equip_animation):
		_play_current_idle()

	weapon_changed.emit(
		current_weapon_index,
		WEAPON_DATA[current_weapon_index]["display_name"]
	)


func play_attack() -> bool:
	if _attack_cooldown_left > 0.0:
		return false

	var attack_animations: Array = WEAPON_DATA[current_weapon_index]["attack_animations"]
	if attack_animations.is_empty():
		return false

	var animation_name: StringName = attack_animations[_attack_variant % attack_animations.size()]
	_attack_variant += 1
	_weapon_models[current_weapon_index].visible = true
	if not _play_animation(animation_name, 0.04):
		return false
	_apply_recoil()
	_attack_cooldown_left = WEAPON_DATA[current_weapon_index]["cooldown"]
	return true


func reload_current_weapon() -> void:
	if _attack_cooldown_left > 0.0:
		return

	var reload_animation: StringName = WEAPON_DATA[current_weapon_index]["reload_animation"]
	if not _play_animation(reload_animation, 0.1):
		return

	var player := _animation_players[current_weapon_index]
	var animation := player.get_animation(reload_animation)
	_attack_cooldown_left = animation.length


func get_weapon_count() -> int:
	return _weapon_slots.size()


func get_current_weapon_name() -> String:
	return WEAPON_DATA[current_weapon_index]["display_name"]


func _create_weapon(index: int) -> void:
	var data := WEAPON_DATA[index]
	var slot := Node3D.new()
	slot.name = "Weapon_%d" % (index + 1)
	add_child(slot)

	var pivot := Node3D.new()
	pivot.name = "ModelPivot"
	pivot.rotation_degrees = data["rotation_degrees"]
	slot.add_child(pivot)

	var weapon_scene: PackedScene = data["scene"]
	var model := weapon_scene.instantiate()
	pivot.add_child(model)
	slot.position = data["manual_position"]
	slot.scale = Vector3.ONE * float(data["manual_scale"])
	_prepare_imported_scene(model)

	_weapon_slots.append(slot)
	_weapon_models.append(model as Node3D)
	var animation_player := _find_animation_player(model)
	_animation_players.append(animation_player)
	_configure_idle_loop(index, animation_player)
	slot.visible = false


func _prepare_imported_scene(model: Node) -> void:
	for imported_camera: Camera3D in model.find_children("*", "Camera3D", true, false):
		imported_camera.current = false

	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 2
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.extra_cull_margin = 100.0


func _update_viewmodel_motion(delta: float) -> void:
	var player := _get_player()
	var local_velocity := Vector3.ZERO
	var horizontal_speed := 0.0
	var moving_on_floor := false
	if player:
		local_velocity = player.global_transform.basis.inverse() * player.velocity
		horizontal_speed = Vector2(player.velocity.x, player.velocity.z).length()
		moving_on_floor = player.is_on_floor() and horizontal_speed > 0.2

	if moving_on_floor:
		var speed_ratio := clampf(horizontal_speed / 9.0, 0.35, 1.0)
		_bob_time += delta * walk_bob_speed * lerpf(0.85, 1.35, speed_ratio)

	var bob := Vector3.ZERO
	var bob_rotation := Vector3.ZERO
	if moving_on_floor:
		var speed_ratio := clampf(horizontal_speed / 9.0, 0.0, 1.0)
		bob.x = sin(_bob_time) * walk_bob_amount * lerpf(0.7, 1.0, speed_ratio)
		bob.y = -absf(cos(_bob_time)) * walk_bob_amount
		bob_rotation.z = sin(_bob_time) * deg_to_rad(0.55)

	var sprinting := (
		moving_on_floor
		and Input.is_action_pressed("sprint")
		and local_velocity.z < -0.5
	)
	_sprint_amount = lerpf(
		_sprint_amount,
		1.0 if sprinting else 0.0,
		_exp_weight(7.0 if sprinting else 11.0, delta)
	)

	var sway_position := Vector3(
		-_mouse_motion.x * sway_position_amount,
		_mouse_motion.y * sway_position_amount,
		0.0
	)
	var sway_rotation := Vector3(
		deg_to_rad(-_mouse_motion.y * sway_rotation_amount),
		deg_to_rad(-_mouse_motion.x * sway_rotation_amount),
		deg_to_rad(_mouse_motion.x * sway_rotation_amount * 0.35)
	)
	var movement_lag := Vector3(
		-local_velocity.x * movement_lag_amount,
		0.0,
		absf(local_velocity.z) * movement_lag_amount * 0.18
	)
	var equip_offset := Vector3(0.06, -equip_drop, 0.08) * _equip_amount
	var equip_rotation := Vector3(
		deg_to_rad(5.0),
		deg_to_rad(-3.0),
		deg_to_rad(-5.0)
	) * _equip_amount
	var sprint_offset := Vector3(0.035, -0.055, 0.025) * _sprint_amount
	var sprint_rotation := Vector3(
		deg_to_rad(3.0),
		deg_to_rad(-2.0),
		deg_to_rad(-3.0)
	) * _sprint_amount

	var target_position := (
		bob + sway_position + movement_lag + equip_offset + sprint_offset + _recoil_position
	)
	var target_rotation := (
		bob_rotation + sway_rotation + equip_rotation + sprint_rotation + _recoil_rotation
	)
	var weight := _exp_weight(motion_smoothing, delta)
	position = position.lerp(target_position, weight)
	rotation.x = lerp_angle(rotation.x, target_rotation.x, weight)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, weight)
	rotation.z = lerp_angle(rotation.z, target_rotation.z, weight)

	_mouse_motion = _mouse_motion.lerp(Vector2.ZERO, _exp_weight(18.0, delta))
	_equip_amount = lerpf(_equip_amount, 0.0, _exp_weight(8.0, delta))
	_recoil_position = _recoil_position.lerp(Vector3.ZERO, _exp_weight(15.0, delta))
	_recoil_rotation = _recoil_rotation.lerp(Vector3.ZERO, _exp_weight(18.0, delta))


func _apply_recoil() -> void:
	var recoil_scale := 0.75
	if current_weapon_index == 0:
		recoil_scale = 1.35
	elif current_weapon_index == 1:
		recoil_scale = 0.55
	var side := -1.0 if _attack_variant % 2 == 0 else 1.0
	_recoil_position += Vector3(side * 0.002, -0.003, 0.025) * recoil_scale
	_recoil_rotation += Vector3(
		deg_to_rad(1.15),
		deg_to_rad(side * 0.2),
		deg_to_rad(side * 0.25)
	) * recoil_scale


func _find_animation_player(model: Node) -> AnimationPlayer:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return null
	return players[0] as AnimationPlayer


func _configure_idle_loop(index: int, player: AnimationPlayer) -> void:
	if player == null:
		return
	var idle_animation: StringName = WEAPON_DATA[index]["idle_animation"]
	if idle_animation.is_empty() or not player.has_animation(idle_animation):
		return
	player.get_animation(idle_animation).loop_mode = Animation.LOOP_LINEAR


func _play_animation(animation_name: StringName, blend_time := 0.12) -> bool:
	if animation_name.is_empty():
		return false

	var player := _animation_players[current_weapon_index]
	if player == null or not player.has_animation(animation_name):
		return false

	player.play(animation_name, blend_time)
	return true


func _play_current_idle() -> void:
	var idle_animation: StringName = WEAPON_DATA[current_weapon_index]["idle_animation"]
	_play_animation(idle_animation)


func _update_weapon_label() -> void:
	if weapon_label == null:
		return
	weapon_label.text = "%d  %s" % [
		current_weapon_index + 1,
		WEAPON_DATA[current_weapon_index]["display_name"],
	]


func _number_key_to_index(keycode: Key) -> int:
	match keycode:
		KEY_1:
			return 0
		KEY_2:
			return 1
		KEY_3:
			return 2
	return -1


func _get_player() -> CharacterBody3D:
	return owner as CharacterBody3D


func _exp_weight(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)
