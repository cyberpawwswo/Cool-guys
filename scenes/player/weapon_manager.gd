extends Node3D


signal weapon_changed(index: int, display_name: String)

const WEAPON_DATA: Array[Dictionary] = [
	{
		"display_name": "Boomstick",
		"scene": preload("res://assets/weapons/shotgun/source/shotgunAnimated.fbx"),
		"attack_animations": [&"Armature|Fire"],
		"reload_animation": &"Armature|ReloadOne",
		"equip_animation": &"Armature|Weild",
		"idle_animation": StringName(),
		"cooldown": 0.65,
		"view_size": 1.15,
		"view_center": Vector3(0.12, -0.24, -0.68),
		"rotation_degrees": Vector3.ZERO,
	},
	{
		"display_name": "Uzi",
		"scene": preload("res://assets/weapons/uzi/source/1Matzh_Uzi_Animations.fbx"),
		"attack_animations": [&"rig|Fire"],
		"reload_animation": &"rig|Reload",
		"equip_animation": &"rig|Equip",
		"idle_animation": &"rig|Idle",
		"cooldown": 0.12,
		"view_size": 0.9,
		"view_center": Vector3(0.14, -0.2, -0.58),
		"rotation_degrees": Vector3.ZERO,
	},
	{
		"display_name": "Beretta",
		"scene": preload("res://assets/weapons/pistol/source/arms@beretta.fbx"),
		"attack_animations": [&"CINEMA_4D_Main"],
		"reload_animation": StringName(),
		"equip_animation": StringName(),
		"idle_animation": StringName(),
		"cooldown": 0.35,
		"view_size": 0.82,
		"view_center": Vector3(0.16, -0.21, -0.56),
		"rotation_degrees": Vector3.ZERO,
	},
	{
		"display_name": "AKS-74",
		"scene": preload("res://assets/weapons/aks74/source/hands_aks74_stalker_soc.fbx"),
		"attack_animations": [&"hud_skelet|Shot"],
		"reload_animation": &"hud_skelet|Reload_f",
		"equip_animation": StringName(),
		"idle_animation": StringName(),
		"cooldown": 0.14,
		"view_size": 1.0,
		"view_center": Vector3(0.12, -0.2, -0.65),
		"rotation_degrees": Vector3(0.0, -90.0, 0.0),
	},
	{
		"display_name": "Leg Kick",
		"scene": preload("res://assets/weapons/legkick/source/legkick.fbx"),
		"attack_animations": [&"Armature|Kick1", &"Armature|Kick2"],
		"reload_animation": StringName(),
		"equip_animation": StringName(),
		"idle_animation": StringName(),
		"cooldown": 0.55,
		"view_size": 0.95,
		"view_center": Vector3(0.0, -0.28, -0.7),
		"rotation_degrees": Vector3.ZERO,
	},
	{
		"display_name": "Remington",
		"scene": preload("res://assets/weapons/remington/source/Arm_remington.fbx"),
		"attack_animations": [&"Armature|SG_FPS_Shot"],
		"reload_animation": &"Armature|SG_FPS_Reload",
		"equip_animation": StringName(),
		"idle_animation": &"Armature|SG_FPS_Idle",
		"cooldown": 1.0,
		"view_size": 1.05,
		"view_center": Vector3(0.12, -0.23, -0.64),
		"rotation_degrees": Vector3.ZERO,
	},
]

@onready var weapon_label: Label = get_node_or_null("../../Control/WeaponLabel")

var current_weapon_index := 0
var _weapon_slots: Array[Node3D] = []
var _animation_players: Array[AnimationPlayer] = []
var _attack_cooldown_left := 0.0
var _attack_variant := 0


func _ready() -> void:
	for index in WEAPON_DATA.size():
		_create_weapon(index)
	select_weapon(0, true)


func _process(delta: float) -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)

	var animation_player := _animation_players[current_weapon_index]
	if animation_player and not animation_player.is_playing():
		_play_current_idle()


func _unhandled_input(event: InputEvent) -> void:
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
	if not _play_animation(animation_name):
		return false
	_attack_cooldown_left = WEAPON_DATA[current_weapon_index]["cooldown"]
	return true


func reload_current_weapon() -> void:
	if _attack_cooldown_left > 0.0:
		return

	var reload_animation: StringName = WEAPON_DATA[current_weapon_index]["reload_animation"]
	if not _play_animation(reload_animation):
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
	_prepare_imported_scene(model)
	_fit_weapon_to_view(slot, float(data["view_size"]), data["view_center"])

	_weapon_slots.append(slot)
	_animation_players.append(_find_animation_player(model))
	slot.visible = false


func _prepare_imported_scene(model: Node) -> void:
	for imported_camera: Camera3D in model.find_children("*", "Camera3D", true, false):
		imported_camera.current = false

	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _fit_weapon_to_view(slot: Node3D, target_size: float, target_center: Vector3) -> void:
	var bounds := _calculate_bounds(slot)
	var longest_side := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if longest_side <= 0.00001:
		return

	var scale_factor := target_size / longest_side
	slot.scale = Vector3.ONE * scale_factor
	slot.position = target_center - bounds.get_center() * scale_factor


func _calculate_bounds(slot: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for mesh: MeshInstance3D in slot.find_children("*", "MeshInstance3D", true, false):
		var relative_transform := slot.global_transform.affine_inverse() * mesh.global_transform
		var mesh_bounds: AABB = relative_transform * mesh.get_aabb()
		if has_bounds:
			bounds = bounds.merge(mesh_bounds)
		else:
			bounds = mesh_bounds
			has_bounds = true
	return bounds


func _find_animation_player(model: Node) -> AnimationPlayer:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return null
	return players[0] as AnimationPlayer


func _play_animation(animation_name: StringName) -> bool:
	if animation_name.is_empty():
		return false

	var player := _animation_players[current_weapon_index]
	if player == null or not player.has_animation(animation_name):
		return false

	player.play(animation_name)
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
