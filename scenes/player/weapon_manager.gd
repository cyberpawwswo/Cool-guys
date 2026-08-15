extends Node3D


signal weapon_changed(index: int, display_name: String)
signal ammo_changed(index: int, magazine: int, reserve: int)

const PISTOL_SLIDE_DURATION := 0.12
const PISTOL_SLIDE_DISTANCE := 0.035
const PISTOL_RELOAD_START := 0.6333333
const PISTOL_RELOAD_END := 1.9333333
const SHOTGUN_RELOAD_DELAY := 0.2

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
		"fire_sound": preload("res://assets/audio/weapons/boomstick_fire.mp3"),
		"reload_sound": preload("res://assets/audio/weapons/boomstick_reload_shell.wav"),
		"fire_volume_db": 2.0,
		"reload_volume_db": -3.0,
		"shot_effect_strength": 1.0,
		"muzzle_position": Vector3(0.145, -0.305, -1.40),
		"muzzle_size": 0.27,
		"muzzle_duration": 0.16,
		"muzzle_light_energy": 18.0,
		"fire_pitch_range": Vector2(0.94, 1.02),
		"fire_tail_pitch": 0.72,
		"fire_tail_volume_db": -8.0,
		"view_recoil_position": Vector3(0.0, -0.026, 0.125),
		"view_recoil_rotation": Vector3(10.5, 1.3, 2.6),
		"uses_ammo": true,
		"magazine_capacity": 6,
		"starting_reserve": 24,
		"reload_amount": 1,
		"attack_animations": [&"Armature|Fire"],
		"procedural_fire": false,
		"reload_animation": &"Armature|ReloadOne",
		"equip_animation": &"Armature|Weild",
		"idle_animation": StringName(),
		"cooldown": 0.65,
		"manual_scale": 4.2,
		"manual_position": Vector3(0.68, -1.77, -2.02),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"hide_when_idle": false,
	},
	{
		"display_name": "Beretta",
		"scene": preload("res://assets/weapons/pistol/source/arms@beretta.fbx"),
		"fire_sound": preload("res://assets/audio/weapons/beretta_fire.mp3"),
		"reload_sound": preload("res://assets/audio/weapons/beretta_reload.mp3"),
		"fire_volume_db": 0.5,
		"reload_volume_db": -3.0,
		"shot_effect_strength": 0.42,
		"muzzle_position": Vector3(0.17, -0.14, -1.03),
		"muzzle_size": 0.14,
		"muzzle_duration": 0.08,
		"muzzle_light_energy": 9.0,
		"fire_pitch_range": Vector2(0.97, 1.04),
		"fire_tail_pitch": 0.84,
		"fire_tail_volume_db": -11.0,
		"view_recoil_position": Vector3(0.0, -0.01, 0.052),
		"view_recoil_rotation": Vector3(4.8, 0.75, 1.15),
		"uses_ammo": true,
		"magazine_capacity": 15,
		"starting_reserve": 60,
		"reload_amount": 15,
		"attack_animations": [],
		"procedural_fire": true,
		"reload_animation": &"CINEMA_4D_Main",
		"equip_animation": StringName(),
		"idle_animation": StringName(),
		"cooldown": 0.35,
		"manual_scale": 6.0,
		"manual_position": Vector3(0.84, -1.53, -1.81),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"hide_when_idle": false,
	},
	{
		"display_name": "Leg Kick",
		"scene": preload("res://assets/weapons/legkick/source/legkick.fbx"),
		"fire_sound": null,
		"reload_sound": null,
		"fire_volume_db": 0.0,
		"reload_volume_db": 0.0,
		"shot_effect_strength": 0.16,
		"muzzle_position": Vector3.ZERO,
		"muzzle_size": 0.0,
		"muzzle_duration": 0.0,
		"muzzle_light_energy": 0.0,
		"fire_pitch_range": Vector2.ONE,
		"fire_tail_pitch": 1.0,
		"fire_tail_volume_db": -80.0,
		"view_recoil_position": Vector3(0.0, -0.004, 0.018),
		"view_recoil_rotation": Vector3(1.4, 0.2, 0.35),
		"uses_ammo": false,
		"magazine_capacity": 0,
		"starting_reserve": 0,
		"reload_amount": 0,
		"attack_animations": [&"Armature|Kick1", &"Armature|Kick2"],
		"procedural_fire": false,
		"reload_animation": StringName(),
		"equip_animation": StringName(),
		"idle_animation": StringName(),
		"cooldown": 0.55,
		"manual_scale": 1.3,
		"manual_position": Vector3(0.03, -1.35, -0.9),
		"rotation_degrees": Vector3(0.0, 180.0, 0.0),
		"hide_when_idle": true,
	},
]

@onready var weapon_label: Label = _get_player().get_node_or_null("Control/WeaponLabel")
@onready var ammo_label: Label = _get_player().get_node_or_null("Control/AmmoLabel")

var current_weapon_index := 0
var _weapon_slots: Array[Node3D] = []
var _weapon_models: Array[Node3D] = []
var _animation_players: Array[AnimationPlayer] = []
var _fire_audio_players: Array[AudioStreamPlayer] = []
var _fire_tail_audio_players: Array[AudioStreamPlayer] = []
var _reload_audio_players: Array[AudioStreamPlayer] = []
var _muzzle_effect_roots: Array[Node3D] = []
var _muzzle_anchors: Array[Node3D] = []
var _muzzle_flash_roots: Array[Node3D] = []
var _muzzle_flash_lights: Array[OmniLight3D] = []
var _muzzle_smoke_particles: Array[CPUParticles3D] = []
var _muzzle_spark_particles: Array[CPUParticles3D] = []
var _muzzle_gas_particles: Array[CPUParticles3D] = []
var _muzzle_flash_times: Array[float] = []
var _procedural_slides: Array[Node3D] = []
var _procedural_slide_positions: Array[Vector3] = []
var _ammo_in_magazine: Array[int] = []
var _ammo_reserve: Array[int] = []
var _slide_fire_time := -1.0
var _pistol_reload_active := false
var _reload_active := false
var _reload_weapon_index := -1
var _pending_reload_amount := 0
var _attack_cooldown_left := 0.0
var _attack_variant := 0
var _mouse_motion := Vector2.ZERO
var _bob_time := 0.0
var _equip_amount := 0.0
var _sprint_amount := 0.0
var _recoil_position := Vector3.ZERO
var _recoil_rotation := Vector3.ZERO
var _recoil_position_velocity := Vector3.ZERO
var _recoil_rotation_velocity := Vector3.ZERO
var _shotgun_reload_delay := -1.0
var _reload_speed_multiplier := 1.0
var _black_white_mode := false


func _ready() -> void:
	for index in WEAPON_DATA.size():
		_ammo_in_magazine.append(int(WEAPON_DATA[index]["magazine_capacity"]))
		_ammo_reserve.append(int(WEAPON_DATA[index]["starting_reserve"]))
		_create_weapon(index)
	select_weapon(0, true)


func _process(delta: float) -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	if _shotgun_reload_delay > 0.0:
		_shotgun_reload_delay -= delta
		if _shotgun_reload_delay <= 0.0:
			_play_audio(_reload_audio_players[0])
	_update_procedural_slide(delta)
	_update_muzzle_flashes(delta)
	_update_viewmodel_motion(delta)

	var animation_player := _animation_players[current_weapon_index]
	if (
		_reload_active
		and _reload_weapon_index == current_weapon_index
		and not animation_player.is_playing()
	):
		_finish_reload()
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
	if wrapped_index != current_weapon_index:
		_cancel_reload()

	for slot_index in _weapon_slots.size():
		_weapon_slots[slot_index].visible = slot_index == wrapped_index
		var player := _animation_players[slot_index]
		if player and slot_index != wrapped_index:
			player.stop()
			_reload_audio_players[slot_index].stop()
			if WEAPON_DATA[slot_index]["procedural_fire"]:
				_reset_procedural_animation(slot_index)

	current_weapon_index = wrapped_index
	_attack_cooldown_left = 0.0
	_attack_variant = 0
	_equip_amount = 1.0
	_recoil_position = Vector3.ZERO
	_recoil_rotation = Vector3.ZERO
	_recoil_position_velocity = Vector3.ZERO
	_recoil_rotation_velocity = Vector3.ZERO
	_weapon_models[current_weapon_index].visible = not WEAPON_DATA[current_weapon_index]["hide_when_idle"]
	_update_weapon_label()
	_update_ammo_label()

	var equip_animation: StringName = WEAPON_DATA[current_weapon_index]["equip_animation"]
	if not _play_animation(equip_animation):
		_play_current_idle()

	weapon_changed.emit(
		current_weapon_index,
		WEAPON_DATA[current_weapon_index]["display_name"]
	)


func play_attack() -> bool:
	if _attack_cooldown_left > 0.0 or _reload_active:
		return false

	var data := WEAPON_DATA[current_weapon_index]
	if data["uses_ammo"] and _ammo_in_magazine[current_weapon_index] <= 0:
		return false
	if data["procedural_fire"] or current_weapon_index == 0:
		_attack_variant += 1
		_weapon_models[current_weapon_index].visible = true
		if data["procedural_fire"]:
			_play_procedural_fire()
		else:
			_set_shotgun_ready_pose()
		_play_fire_audio()
		_trigger_muzzle_flash(current_weapon_index)
		_consume_round()
		_apply_recoil()
		_attack_cooldown_left = float(data["cooldown"])
		return true

	var attack_animations: Array = data["attack_animations"]
	if attack_animations.is_empty():
		return false

	var animation_name: StringName = attack_animations[_attack_variant % attack_animations.size()]
	_attack_variant += 1
	_weapon_models[current_weapon_index].visible = true
	if not _play_animation(animation_name, 0.04):
		return false
	_play_fire_audio()
	_trigger_muzzle_flash(current_weapon_index)
	_consume_round()
	_apply_recoil()
	_attack_cooldown_left = float(data["cooldown"])
	return true


func reload_current_weapon() -> void:
	if _attack_cooldown_left > 0.0 or _reload_active:
		return

	var data := WEAPON_DATA[current_weapon_index]
	if not data["uses_ammo"]:
		return
	var missing_ammo := int(data["magazine_capacity"]) - _ammo_in_magazine[current_weapon_index]
	if missing_ammo <= 0 or _ammo_reserve[current_weapon_index] <= 0:
		return
	var reload_amount := mini(
		missing_ammo,
		mini(_ammo_reserve[current_weapon_index], int(data["reload_amount"]))
	)
	var reload_animation: StringName = data["reload_animation"]
	if data["procedural_fire"]:
		var pistol_player := _animation_players[current_weapon_index]
		if pistol_player == null or not pistol_player.has_animation(reload_animation):
			return
		pistol_player.active = true
		pistol_player.speed_scale = _reload_speed_multiplier
		pistol_player.play_section(
			reload_animation,
			PISTOL_RELOAD_START,
			PISTOL_RELOAD_END,
			0.08
		)
		_play_audio(_reload_audio_players[current_weapon_index])
		_pistol_reload_active = true
		_begin_reload(reload_amount)
		_attack_cooldown_left = (PISTOL_RELOAD_END - PISTOL_RELOAD_START) / _reload_speed_multiplier
		return

	if current_weapon_index == 0:
		_set_shotgun_ready_pose()
	if not _play_animation(reload_animation, 0.1):
		return
	_play_audio(_reload_audio_players[current_weapon_index])
	_begin_reload(reload_amount)

	var player := _animation_players[current_weapon_index]
	player.speed_scale = _reload_speed_multiplier
	var animation := player.get_animation(reload_animation)
	_attack_cooldown_left = animation.length / _reload_speed_multiplier


func get_weapon_count() -> int:
	return _weapon_slots.size()


func get_current_weapon_name() -> String:
	return WEAPON_DATA[current_weapon_index]["display_name"]


func get_current_ammo() -> int:
	return _ammo_in_magazine[current_weapon_index]


func get_current_reserve_ammo() -> int:
	return _ammo_reserve[current_weapon_index]


func is_reloading() -> bool:
	return _reload_active


func _consume_round() -> void:
	if not WEAPON_DATA[current_weapon_index]["uses_ammo"]:
		return
	_ammo_in_magazine[current_weapon_index] = maxi(
		_ammo_in_magazine[current_weapon_index] - 1,
		0
	)
	_update_ammo_label()
	_emit_ammo_changed(current_weapon_index)


func _begin_reload(amount: int) -> void:
	_reload_active = true
	_reload_weapon_index = current_weapon_index
	_pending_reload_amount = amount


func set_reload_speed(multiplier: float) -> void:
	_reload_speed_multiplier = maxf(multiplier, 0.1)


func set_black_white_mode(enabled: bool) -> void:
	_black_white_mode = enabled


func _finish_reload() -> void:
	var weapon_index := _reload_weapon_index
	var reload_amount := _pending_reload_amount
	_reload_active = false
	_reload_weapon_index = -1
	_pending_reload_amount = 0
	if weapon_index >= 0:
		var player := _animation_players[weapon_index]
		if player:
			player.speed_scale = 1.0
		if weapon_index == 0:
			_set_shotgun_ready_pose()
	if weapon_index < 0 or reload_amount <= 0:
		return

	_ammo_in_magazine[weapon_index] += reload_amount
	_ammo_reserve[weapon_index] -= reload_amount
	if weapon_index == 1 and _pistol_reload_active:
		_reset_procedural_animation(weapon_index)
	_update_ammo_label()
	_emit_ammo_changed(weapon_index)


func _cancel_reload() -> void:
	if not _reload_active:
		return
	var weapon_index := _reload_weapon_index
	_reload_active = false
	_reload_weapon_index = -1
	_pending_reload_amount = 0
	if weapon_index >= 0:
		_reload_audio_players[weapon_index].stop()
		var player := _animation_players[weapon_index]
		if player:
			player.speed_scale = 1.0
		if weapon_index == 0:
			_set_shotgun_ready_pose()


func _emit_ammo_changed(weapon_index: int) -> void:
	ammo_changed.emit(
		weapon_index,
		_ammo_in_magazine[weapon_index],
		_ammo_reserve[weapon_index]
	)


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
	var slide := model.find_child("slide", true, false) as Node3D
	if data["procedural_fire"] and slide:
		_procedural_slides.append(slide)
		_procedural_slide_positions.append(slide.position)
	else:
		_procedural_slides.append(null)
		_procedural_slide_positions.append(Vector3.ZERO)
	var animation_player := _find_animation_player(model)
	if data["procedural_fire"] and animation_player:
		animation_player.active = false
	_animation_players.append(animation_player)
	_fire_audio_players.append(_create_audio_player(
		"FireAudio_%d" % (index + 1),
		data["fire_sound"],
		data["fire_volume_db"],
		4
	))
	_fire_tail_audio_players.append(_create_audio_player(
		"FireTailAudio_%d" % (index + 1),
		data["fire_sound"],
		data["fire_tail_volume_db"],
		4
	))
	_reload_audio_players.append(_create_audio_player(
		"ReloadAudio_%d" % (index + 1),
		data["reload_sound"],
		data["reload_volume_db"],
		1
	))
	_create_muzzle_flash(index, data, model)
	_configure_idle_loop(index, animation_player)
	slot.visible = false


func _prepare_imported_scene(model: Node) -> void:
	for imported_camera: Camera3D in model.find_children("*", "Camera3D", true, false):
		imported_camera.current = false

	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 2
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.extra_cull_margin = 100.0


func _create_audio_player(
	player_name: String,
	stream: AudioStream,
	volume_db: float,
	max_polyphony: int
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.volume_db = volume_db
	player.max_polyphony = max_polyphony
	add_child(player)
	return player


func _play_audio(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.play()


func _play_fire_audio() -> void:
	var data := WEAPON_DATA[current_weapon_index]
	var pitch_range: Vector2 = data["fire_pitch_range"]
	var fire_player := _fire_audio_players[current_weapon_index]
	fire_player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	_play_audio(fire_player)
	var tail_player := _fire_tail_audio_players[current_weapon_index]
	tail_player.pitch_scale = float(data["fire_tail_pitch"])
	_play_audio(tail_player)
	if WEAPON_DATA[current_weapon_index]["display_name"] == "Boomstick":
		_shotgun_reload_delay = SHOTGUN_RELOAD_DELAY


func _create_muzzle_flash(index: int, data: Dictionary, model: Node3D) -> void:
	var flash_size := float(data["muzzle_size"])
	if flash_size <= 0.0:
		_muzzle_effect_roots.append(null)
		_muzzle_anchors.append(null)
		_muzzle_flash_roots.append(null)
		_muzzle_flash_lights.append(null)
		_muzzle_smoke_particles.append(null)
		_muzzle_spark_particles.append(null)
		_muzzle_gas_particles.append(null)
		_muzzle_flash_times.append(0.0)
		return

	var desired_global_position := to_global(data["muzzle_position"])
	var muzzle_anchor := _create_muzzle_anchor(index, model, desired_global_position)
	var effect_root := Node3D.new()
	effect_root.name = "MuzzleEffects_%d" % (index + 1)
	add_child(effect_root)
	effect_root.global_position = muzzle_anchor.global_position

	var flash_root := Node3D.new()
	flash_root.name = "MuzzleFlash_%d" % (index + 1)
	flash_root.visible = false
	effect_root.add_child(flash_root)

	var flash_shader := Shader.new()
	flash_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, fog_disabled;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered);
	float glow = 1.0 - smoothstep(0.08, 0.5, radius);
	float horizontal = (1.0 - smoothstep(0.015, 0.09, abs(centered.y)))
		* (1.0 - smoothstep(0.08, 0.5, abs(centered.x)));
	float vertical = (1.0 - smoothstep(0.015, 0.09, abs(centered.x)))
		* (1.0 - smoothstep(0.08, 0.5, abs(centered.y)));
	float alpha = clamp(glow * 0.82 + max(horizontal, vertical) * 0.75, 0.0, 1.0);
	vec3 hot = vec3(1.0, 1.0, 0.72);
	vec3 orange = vec3(1.0, 0.22, 0.015);
	vec3 color = mix(hot, orange, smoothstep(0.04, 0.38, radius));
	ALBEDO = color;
	EMISSION = color * 8.0;
	ALPHA = alpha;
}
"""
	var flash_material := ShaderMaterial.new()
	flash_material.shader = flash_shader
	var flash_quad := QuadMesh.new()
	flash_quad.size = Vector2.ONE * flash_size
	flash_quad.material = flash_material
	var flash_mesh := MeshInstance3D.new()
	flash_mesh.mesh = flash_quad
	flash_mesh.layers = 2
	flash_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash_root.add_child(flash_mesh)
	var flash_glow := MeshInstance3D.new()
	flash_glow.name = "FlashGlow"
	flash_glow.mesh = _create_soft_particle_mesh(
		Vector2.ONE * flash_size * 1.85,
		Color(1.0, 0.28, 0.025, 0.42),
		true
	)
	flash_glow.layers = 2
	flash_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash_root.add_child(flash_glow)

	var flash_light := OmniLight3D.new()
	flash_light.light_color = Color(1.0, 0.42, 0.1)
	flash_light.light_energy = 0.0
	flash_light.light_cull_mask = 2
	flash_light.omni_range = 3.2
	flash_light.shadow_enabled = false
	effect_root.add_child(flash_light)

	var smoke_particles := _create_smoke_particles(index, flash_size)
	effect_root.add_child(smoke_particles)
	var spark_particles := _create_spark_particles(index, flash_size)
	effect_root.add_child(spark_particles)
	var gas_particles := _create_gas_particles(index, flash_size)
	effect_root.add_child(gas_particles)

	_muzzle_effect_roots.append(effect_root)
	_muzzle_anchors.append(muzzle_anchor)
	_muzzle_flash_roots.append(flash_root)
	_muzzle_flash_lights.append(flash_light)
	_muzzle_smoke_particles.append(smoke_particles)
	_muzzle_spark_particles.append(spark_particles)
	_muzzle_gas_particles.append(gas_particles)
	_muzzle_flash_times.append(0.0)


func _create_muzzle_anchor(
	index: int,
	model: Node3D,
	desired_global_position: Vector3
) -> Node3D:
	var anchor: Node3D
	if index == 0:
		var shotgun_anchor := Node3D.new()
		shotgun_anchor.name = "BoomstickMuzzleAnchor"
		model.add_child(shotgun_anchor)
		anchor = shotgun_anchor
	else:
		var pistol := model.find_child("pistol", true, false) as Node3D
		var pistol_anchor := Node3D.new()
		pistol_anchor.name = "BerettaMuzzleAnchor"
		pistol.add_child(pistol_anchor)
		anchor = pistol_anchor
	anchor.global_position = desired_global_position
	return anchor


func _create_smoke_particles(index: int, flash_size: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "MuzzleSmoke_%d" % (index + 1)
	particles.amount = 14 if index == 0 else 9
	particles.lifetime = 1.05 if index == 0 else 0.72
	particles.one_shot = true
	particles.explosiveness = 0.82
	particles.randomness = 0.5
	particles.local_coords = false
	particles.direction = Vector3(0.0, 0.35, -1.0).normalized()
	particles.spread = 38.0
	particles.gravity = Vector3(0.0, 0.3, 0.0)
	particles.initial_velocity_min = 0.12
	particles.initial_velocity_max = 0.5 if index == 0 else 0.34
	particles.scale_amount_min = 0.7
	particles.scale_amount_max = 1.75
	var smoke_scale_curve := Curve.new()
	smoke_scale_curve.add_point(Vector2(0.0, 0.18))
	smoke_scale_curve.add_point(Vector2(0.22, 0.82))
	smoke_scale_curve.add_point(Vector2(1.0, 1.0))
	particles.scale_amount_curve = smoke_scale_curve
	particles.mesh = _create_soft_particle_mesh(
		Vector2.ONE * flash_size * (0.62 if index == 0 else 0.5),
		Color(0.42, 0.44, 0.48, 0.22),
		false
	)
	particles.layers = 2
	particles.emitting = false
	return particles


func _create_spark_particles(index: int, flash_size: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "MuzzleSparks_%d" % (index + 1)
	particles.amount = 28 if index == 0 else 16
	particles.lifetime = 0.3 if index == 0 else 0.21
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.35
	particles.local_coords = true
	particles.direction = Vector3(0.0, 0.0, -1.0)
	particles.spread = 46.0
	particles.gravity = Vector3(0.0, -2.4, 0.0)
	particles.initial_velocity_min = 0.55
	particles.initial_velocity_max = 1.65 if index == 0 else 1.35
	particles.scale_amount_min = 0.55
	particles.scale_amount_max = 1.2
	particles.angle_min = -35.0
	particles.angle_max = 35.0
	particles.particle_flag_align_y = true
	particles.mesh = _create_soft_particle_mesh(
		Vector2(flash_size * 0.07, flash_size * 0.62),
		Color(1.0, 0.38, 0.025, 1.0),
		true
	)
	particles.layers = 2
	particles.emitting = false
	return particles


func _create_gas_particles(index: int, flash_size: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "MuzzleGas_%d" % (index + 1)
	particles.amount = 18 if index == 0 else 10
	particles.lifetime = 0.19 if index == 0 else 0.13
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.42
	particles.local_coords = true
	particles.direction = Vector3(0.0, 0.05, -1.0).normalized()
	particles.spread = 30.0
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.25
	particles.initial_velocity_max = 0.78 if index == 0 else 0.62
	particles.scale_amount_min = 0.45
	particles.scale_amount_max = 1.25
	var gas_scale_curve := Curve.new()
	gas_scale_curve.add_point(Vector2(0.0, 1.0))
	gas_scale_curve.add_point(Vector2(1.0, 0.08))
	particles.scale_amount_curve = gas_scale_curve
	particles.mesh = _create_soft_particle_mesh(
		Vector2.ONE * flash_size * (0.32 if index == 0 else 0.28),
		Color(1.0, 0.31, 0.025, 0.78),
		true
	)
	particles.layers = 2
	particles.emitting = false
	return particles


func _create_soft_particle_mesh(
	size: Vector2,
	color: Color,
	additive: bool
) -> QuadMesh:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, %s, cull_disabled, depth_draw_never, depth_test_disabled, fog_disabled;
uniform vec4 particle_color : source_color;

void fragment() {
	float radius = length(UV - vec2(0.5));
	float alpha = (1.0 - smoothstep(0.12, 0.5, radius)) * particle_color.a;
	ALBEDO = particle_color.rgb;
	EMISSION = particle_color.rgb * %s;
	ALPHA = alpha;
}
""" % ["blend_add" if additive else "blend_mix", "7.5" if additive else "0.75"]
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("particle_color", color)
	var quad := QuadMesh.new()
	quad.size = size
	quad.material = material
	return quad


func _trigger_muzzle_flash(index: int) -> void:
	if _black_white_mode:
		return
	var flash_root := _muzzle_flash_roots[index]
	if flash_root == null:
		return
	_muzzle_anchors[index].global_position = to_global(WEAPON_DATA[index]["muzzle_position"])
	_sync_muzzle_effect(index)
	_muzzle_flash_times[index] = float(WEAPON_DATA[index]["muzzle_duration"])
	flash_root.scale = Vector3.ONE * 0.7
	flash_root.rotation.z = randf_range(-0.35, 0.35)
	flash_root.visible = true
	_muzzle_flash_lights[index].light_energy = float(
		WEAPON_DATA[index]["muzzle_light_energy"]
	)
	_muzzle_smoke_particles[index].restart()
	_muzzle_smoke_particles[index].emitting = true
	_muzzle_spark_particles[index].restart()
	_muzzle_spark_particles[index].emitting = true
	_muzzle_gas_particles[index].restart()
	_muzzle_gas_particles[index].emitting = true


func _sync_muzzle_effect(index: int) -> void:
	var effect_root := _muzzle_effect_roots[index]
	var anchor := _muzzle_anchors[index]
	if effect_root != null and anchor != null:
		effect_root.global_position = anchor.global_position


func _update_muzzle_flashes(delta: float) -> void:
	for index in _muzzle_flash_roots.size():
		var flash_root := _muzzle_flash_roots[index]
		if flash_root == null:
			continue
		_sync_muzzle_effect(index)
		if _muzzle_flash_times[index] <= 0.0:
			continue
		_muzzle_flash_times[index] = maxf(_muzzle_flash_times[index] - delta, 0.0)
		var duration := float(WEAPON_DATA[index]["muzzle_duration"])
		var remaining := _muzzle_flash_times[index] / duration
		flash_root.scale = Vector3.ONE * lerpf(1.8, 0.65, remaining)
		_muzzle_flash_lights[index].light_energy = (
			float(WEAPON_DATA[index]["muzzle_light_energy"]) * remaining * remaining
		)
		if _muzzle_flash_times[index] <= 0.0:
			flash_root.visible = false
			_muzzle_flash_lights[index].light_energy = 0.0


func _update_viewmodel_motion(delta: float) -> void:
	_update_recoil_spring(delta)
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


func _update_recoil_spring(delta: float) -> void:
	var step := minf(delta, 1.0 / 30.0)
	_recoil_position_velocity += (
		-_recoil_position * 185.0 - _recoil_position_velocity * 21.0
	) * step
	_recoil_rotation_velocity += (
		-_recoil_rotation * 210.0 - _recoil_rotation_velocity * 23.0
	) * step
	_recoil_position += _recoil_position_velocity * step
	_recoil_rotation += _recoil_rotation_velocity * step
	if _recoil_position.length_squared() < 0.0000001:
		_recoil_position = Vector3.ZERO
	if _recoil_position_velocity.length_squared() < 0.0000001:
		_recoil_position_velocity = Vector3.ZERO
	if _recoil_rotation.length_squared() < 0.0000001:
		_recoil_rotation = Vector3.ZERO
	if _recoil_rotation_velocity.length_squared() < 0.0000001:
		_recoil_rotation_velocity = Vector3.ZERO


func _play_procedural_fire() -> void:
	var slide := _procedural_slides[current_weapon_index]
	if slide == null:
		return
	_slide_fire_time = 0.0
	slide.position = _procedural_slide_positions[current_weapon_index]


func _reset_procedural_animation(index: int) -> void:
	var player := _animation_players[index]
	var animation_name: StringName = WEAPON_DATA[index]["reload_animation"]
	player.active = true
	player.play(animation_name)
	player.seek(0.0, true)
	player.stop(true)
	player.active = false
	_pistol_reload_active = false


func _set_shotgun_ready_pose() -> void:
	var player := _animation_players[0]
	var equip_animation: StringName = WEAPON_DATA[0]["equip_animation"]
	if player == null or not player.has_animation(equip_animation):
		return
	player.active = true
	player.speed_scale = 1.0
	player.play(equip_animation)
	player.seek(player.get_animation(equip_animation).length, true)
	player.stop(true)


func _update_procedural_slide(delta: float) -> void:
	if _slide_fire_time < 0.0:
		return

	var slide := _procedural_slides[1]
	var rest_position := _procedural_slide_positions[1]
	_slide_fire_time = minf(_slide_fire_time + delta, PISTOL_SLIDE_DURATION)
	var progress := _slide_fire_time / PISTOL_SLIDE_DURATION
	var slide_amount := sin(progress * PI)
	slide.position = rest_position + Vector3(
		0.0,
		0.0,
		-PISTOL_SLIDE_DISTANCE * slide_amount
	)

	if _slide_fire_time >= PISTOL_SLIDE_DURATION:
		slide.position = rest_position
		_slide_fire_time = -1.0


func _apply_recoil() -> void:
	var data := WEAPON_DATA[current_weapon_index]
	var side := -1.0 if _attack_variant % 2 == 0 else 1.0
	var kick_position: Vector3 = data["view_recoil_position"]
	kick_position.x += side * (0.008 if current_weapon_index == 0 else 0.003)
	var kick_rotation_degrees: Vector3 = data["view_recoil_rotation"]
	kick_rotation_degrees.y *= side
	kick_rotation_degrees.z *= side
	var kick_rotation := Vector3(
		deg_to_rad(kick_rotation_degrees.x),
		deg_to_rad(kick_rotation_degrees.y),
		deg_to_rad(kick_rotation_degrees.z)
	)
	_recoil_position += kick_position * 0.35
	_recoil_position_velocity += kick_position * 17.0
	_recoil_rotation += kick_rotation * 0.32
	_recoil_rotation_velocity += kick_rotation * 18.0
	var player := _get_player()
	if player and player.has_method("apply_weapon_recoil"):
		player.call(
			"apply_weapon_recoil",
			float(data["shot_effect_strength"]),
			current_weapon_index
		)


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


func _update_ammo_label() -> void:
	if ammo_label == null:
		return
	var uses_ammo: bool = WEAPON_DATA[current_weapon_index]["uses_ammo"]
	ammo_label.visible = uses_ammo
	if uses_ammo:
		ammo_label.text = "%d / %d" % [
			_ammo_in_magazine[current_weapon_index],
			_ammo_reserve[current_weapon_index],
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
