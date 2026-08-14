extends Node3D


signal weapon_changed(index: int, display_name: String)

@export_category("Viewmodel Motion")
@export var motion_smoothing := 16.0
@export var sway_position_amount := 0.00045
@export var sway_rotation_amount := 0.045
@export var movement_lag_amount := 0.012
@export var walk_bob_amount := 0.012
@export var walk_bob_speed := 10.0
@export var equip_drop := 0.22

const WEAPON_DATA: Array[Dictionary] = [
	{
		"display_name": "Boomstick",
		"scene": preload("res://assets/weapons/shotgun/source/shotgunAnimated.fbx"),
		"attack_animations": [&"Armature|Fire"],
		"reload_animation": &"Armature|ReloadOne",
		"equip_animation": &"Armature|Weild",
		"idle_animation": StringName(),
		"cooldown": 0.65,
		"manual_scale": 1.05,
		"manual_position": Vector3(0.22, -0.58, -0.65),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"use_imported_camera": false,
		"view_offset": Vector3.ZERO,
		"hide_when_idle": false,
	},
	{
		"display_name": "Uzi",
		"scene": preload("res://assets/weapons/uzi/source/1Matzh_Uzi_Animations.fbx"),
		"attack_animations": [&"rig|Fire"],
		"reload_animation": &"rig|Reload",
		"equip_animation": &"rig|Equip",
		"idle_animation": &"rig|Idle",
		"cooldown": 0.12,
		"manual_scale": 1.25,
		"manual_position": Vector3.ZERO,
		"rotation_degrees": Vector3.ZERO,
		"use_imported_camera": true,
		"view_offset": Vector3(0.12, -0.3, -0.5),
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
		"manual_scale": 1.5,
		"manual_position": Vector3(0.27, -0.5, -0.58),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"use_imported_camera": false,
		"view_offset": Vector3.ZERO,
		"hide_when_idle": false,
	},
	{
		"display_name": "AKS-74",
		"scene": preload("res://assets/weapons/aks74/source/hands_aks74_stalker_soc.fbx"),
		"attack_animations": [&"hud_skelet|Shot"],
		"reload_animation": &"hud_skelet|Reload_f",
		"equip_animation": StringName(),
		"idle_animation": &"hud_skelet|Walk_001",
		"cooldown": 0.14,
		"manual_scale": 1.2,
		"manual_position": Vector3.ZERO,
		"rotation_degrees": Vector3.ZERO,
		"use_imported_camera": true,
		"view_offset": Vector3(0.15, -0.32, -0.62),
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
		"manual_scale": 0.9,
		"manual_position": Vector3(0.12, -0.55, -0.72),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"use_imported_camera": false,
		"view_offset": Vector3.ZERO,
		"hide_when_idle": true,
	},
	{
		"display_name": "Remington",
		"scene": preload("res://assets/weapons/remington/source/Arm_remington.fbx"),
		"attack_animations": [&"Armature|SG_FPS_Shot"],
		"reload_animation": &"Armature|SG_FPS_Reload",
		"equip_animation": StringName(),
		"idle_animation": &"Armature|SG_FPS_Idle",
		"cooldown": 1.0,
		"manual_scale": 0.8,
		"manual_position": Vector3(0.14, -0.37, -0.72),
		"rotation_degrees": Vector3.ZERO,
		"use_imported_camera": false,
		"view_offset": Vector3.ZERO,
		"hide_when_idle": false,
	},
]

@onready var weapon_label: Label = get_node_or_null("../../Control/WeaponLabel")

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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_motion += event.relative
		_mouse_motion.x = clampf(_mouse_motion.x, -55.0, 55.0)
		_mouse_motion.y = clampf(_mouse_motion.y, -40.0, 40.0)

	if event is InputEventKey and event.pressed and not event.echo:
		var number_index := _number_key_to_index(event.physical_keycode)
		if number_index >= 0:
			select_weapon(number_index)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_R:
			reload_current_weapon()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_weapon(current_weapon_index - 1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_weapon(current_weapon_index + 1)
			get_viewport().set_input_as_handled()


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
	_apply_asset_fixes(index, model)
	if data["use_imported_camera"]:
		_align_to_imported_camera(pivot, model)
		slot.position = data["view_offset"]
	else:
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


func _align_to_imported_camera(pivot: Node3D, model: Node) -> void:
	var cameras := model.find_children("*", "Camera3D", true, false)
	if cameras.is_empty():
		return

	var imported_camera := cameras[0] as Camera3D
	var camera_in_pivot_space := pivot.global_transform.affine_inverse() * imported_camera.global_transform
	pivot.transform = camera_in_pivot_space.affine_inverse()


func _apply_asset_fixes(index: int, model: Node) -> void:
	match index:
		1:
			_hide_node(model, "Aim")
			_hide_node(model, "Background2")
			_set_surface_material(model, "Mesh", 0, _create_material(
				"res://assets/weapons/uzi/textures/Face_Basecolor.png",
				"res://assets/weapons/uzi/textures/Face_Normal.png"
			))
			_set_surface_material(model, "Mesh", 1, _create_material(
				"res://assets/weapons/uzi/textures/Cloths_BaseColor.1002.png",
				"res://assets/weapons/uzi/textures/Cloths_Normal.1002.png",
				"res://assets/weapons/uzi/textures/Cloths_Roughness.1002.png",
				"res://assets/weapons/uzi/textures/Cloths_Metallic.1002.png"
			))
			_set_surface_material(model, "Mesh", 2, _create_material(
				"res://assets/weapons/uzi/textures/Watch_BaseColor.1004.png",
				"res://assets/weapons/uzi/textures/Watch_Normal.1004.png",
				"res://assets/weapons/uzi/textures/Watch_Roughness.1004.png",
				"res://assets/weapons/uzi/textures/Watch_Metallic.1004.png"
			))
			_set_surface_material(model, "Mesh", 3, _create_material(
				"res://assets/weapons/uzi/textures/Watch_BaseColor.1004.png",
				"res://assets/weapons/uzi/textures/Watch_Normal.1004.png",
				"res://assets/weapons/uzi/textures/Watch_Roughness.1004.png",
				"res://assets/weapons/uzi/textures/Watch_Metallic.1004.png"
			))
			_set_surface_material(model, "Mesh", 4, _create_material(
				"res://assets/weapons/uzi/textures/Gloves_BaseColor.1003.png",
				"res://assets/weapons/uzi/textures/Gloves_Normal.1003.png",
				"res://assets/weapons/uzi/textures/Gloves_Roughness.1003.png",
				"res://assets/weapons/uzi/textures/Gloves_Metallic.1003.png"
			))
			_set_surface_material(model, "UZI", 0, _create_material(
				"res://assets/weapons/uzi/textures/UZI_Base_color.png",
				"res://assets/weapons/uzi/textures/UZI_Normal_OpenGL.png",
				"res://assets/weapons/uzi/textures/UZI_Roughness.png",
				"res://assets/weapons/uzi/textures/UZI_Metallic.png"
			))
			_set_surface_material(model, "UZI", 1, _create_material(
				"res://assets/weapons/uzi/textures/UZI_Magazine_and_Bullet_Base_color.png",
				"res://assets/weapons/uzi/textures/UZI_Magazine_and_Bullet_Normal_OpenGL.png",
				"res://assets/weapons/uzi/textures/UZI_Magazine_and_Bullet_Roughness.png",
				"res://assets/weapons/uzi/textures/UZI_Magazine_and_Bullet_Metallic.png"
			))
		3:
			_hide_node(model, "shape_hand_ik_l")
			_hide_node(model, "shape_hand_ik_r")
			var hands_material := _create_material(
				"res://assets/weapons/aks74/textures/act_arm_perchatka.png"
			)
			var weapon_material := _create_material(
				"res://assets/weapons/aks74/textures/wpn_ak74.png"
			)
			var attachment_material := StandardMaterial3D.new()
			attachment_material.albedo_color = Color(0.12, 0.13, 0.14)
			attachment_material.metallic = 0.65
			attachment_material.roughness = 0.42
			_set_surface_material(model, "hud_mesh", 0, hands_material)
			_set_surface_material(model, "hud_mesh", 1, weapon_material)
			for surface in range(2, 4):
				_set_surface_material(model, "hud_mesh", surface, attachment_material)


func _hide_node(model: Node, node_name: String) -> void:
	var found := model.find_child(node_name, true, false) as Node3D
	if found:
		found.visible = false


func _set_surface_material(
	model: Node,
	mesh_name: String,
	surface: int,
	material: StandardMaterial3D
) -> void:
	var mesh_instance := model.find_child(mesh_name, true, false) as MeshInstance3D
	if mesh_instance == null or mesh_instance.mesh == null:
		return
	if surface < 0 or surface >= mesh_instance.mesh.get_surface_count():
		return
	mesh_instance.set_surface_override_material(surface, material)


func _create_material(
	albedo_path: String,
	normal_path := "",
	roughness_path := "",
	metallic_path := ""
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(albedo_path) as Texture2D
	if not normal_path.is_empty():
		material.normal_enabled = true
		material.normal_texture = load(normal_path) as Texture2D
	if not roughness_path.is_empty():
		material.roughness_texture = load(roughness_path) as Texture2D
	if not metallic_path.is_empty():
		material.metallic_texture = load(metallic_path) as Texture2D
	return material


func _update_viewmodel_motion(delta: float) -> void:
	var player := get_parent().get_parent() as CharacterBody3D
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
	var sprint_offset := Vector3(0.075, -0.105, 0.07) * _sprint_amount
	var sprint_rotation := Vector3(
		deg_to_rad(7.0),
		deg_to_rad(-4.0),
		deg_to_rad(-7.0)
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
	if current_weapon_index in [0, 5]:
		recoil_scale = 1.35
	elif current_weapon_index in [1, 3]:
		recoil_scale = 0.55
	var side := -1.0 if _attack_variant % 2 == 0 else 1.0
	_recoil_position += Vector3(side * 0.004, -0.006, 0.045) * recoil_scale
	_recoil_rotation += Vector3(
		deg_to_rad(2.1),
		deg_to_rad(side * 0.35),
		deg_to_rad(side * 0.45)
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
		KEY_4:
			return 3
		KEY_5:
			return 4
		KEY_6:
			return 5
	return -1


func _exp_weight(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)
