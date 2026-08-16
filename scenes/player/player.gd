extends CharacterBody3D

var _step_sound := preload("res://assets/audio/player/steps.mp3")
var _run_sound := preload("res://assets/audio/player/ran.mp3")
var _dash_sound := preload("res://assets/audio/player/sleash.mp3")
var _headbutt_sound := preload("res://assets/audio/player/headbut.mp3")

@export_category("Movement")
@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var ground_acceleration := 32.0
@export var ground_deceleration := 26.0
@export var air_acceleration := 8.0
@export var jump_velocity := 4.5
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12

@export_category("Dash")
@export var dash_speed := 18.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.8
@export var dash_fov_boost := 7.0

@export_category("Web Shooter")
@export var web_range := 95.0
@export var web_min_anchor_height := 2.0
@export var web_air_anchor_drop := 8.0
@export var web_rope_slack := 0.82
@export var web_min_rope_length := 3.5
@export var web_tension := 28.0
@export var web_spring_strength := 12.0
@export var web_radial_damping := 13.0
@export var web_steer_acceleration := 23.0
@export var web_forward_assist := 20.0
@export var web_cruise_speed := 17.0
@export var web_reel_speed := 12.0
@export var web_extend_speed := 8.0
@export var web_attach_pull := 7.0
@export var web_attach_launch := 8.5
@export var web_glow_pull_speed := 18.0
@export var web_release_boost := 8.0
@export var web_max_speed := 48.0
@export var web_air_drag := 0.012
@export var web_camera_roll_degrees := 5.0
@export var web_fov_boost := 9.0
@export var web_shot_speed := 2700.0
@export var web_visual_segments := 20
@export var web_visual_pixel_width := 4.0
@export var web_visual_depth := 5.0

@export_category("Camera")
@export var mouse_sensitivity := 0.005
@export var camera_smoothing := 14.0
@export var walk_bob_amount := 0.035
@export var sprint_bob_amount := 0.055
@export var bob_frequency := 2.1
@export var strafe_roll_degrees := 1.8
@export var turn_roll_degrees := 1.25
@export var sprint_fov_boost := 4.0
@export var aim_fov := 10.0
@export var aim_sensitivity_multiplier := 0.4
@export var weapon_recoil_recovery := 10.0

@export_category("Headbutt")
@export var close_distance := 2.0
@export var close_multiplier := 3.0
@export var impulse := 20.0
@export var headbutt_duration := 2.0
@export var headbutt_cooldown := 2.25
@export var headbutt_lift := 0.14
@export var headbutt_drop := 0.08
@export var headbutt_reach := 0.32
@export var headbutt_windup_back := 0.22
@export var headbutt_upward_velocity := 8.0
@export var hold_distance := 1.6
@export var hold_lift := 0.7
@export var carry_speed := 10.0
@export var carry_rot_speed := 6.0
@export var headbutt_windup_tilt_degrees := 42.0
@export var headbutt_tilt_degrees := 18.0

@export_category("Black & White")
@export var blink_interval := 2.5
@export var blink_strength := 0.45
@export var blink_fade_speed := 1.8
@export var bw_speed_multiplier := 1.35
@export var bw_dash_speed := 24.0
@export var bw_dash_duration := 0.3
@export var bw_reload_speed_multiplier := 1.6

@export_category("Health")
@export var max_hp := 100.0
@export var impact_damage_threshold := 14.0
@export var impact_damage_multiplier := 0.8
@export var damage_flash_intensity := 0.045
@export var damage_flash_decay := 3.0
@export var damage_sound_volume_db := -6.0

@export_category("Modes")
@export var creative_mode := false

@export_category("Audio")
@export var footstep_volume_db := 0.0
@export var run_volume_db := 0.0
@export var dash_volume_db := 0.0
@export var headbutt_volume_db := 0.0

@onready var camera: Camera3D = $Camera3D
@onready var ray: RayCast3D = $Camera3D/RayCast3D
@onready var weapon_manager = $Control/ViewmodelContainer/ViewmodelViewport/ViewmodelCamera/WeaponManager
@onready var gray_filter: ColorRect = $Effects/GrayFilter
@onready var blink_overlay: ColorRect = $Effects/BlinkOverlay
@onready var shot_flash: ColorRect = $Effects/ShotFlash
@onready var pause_menu: Control = $PauseMenus/PauseMenu
@onready var pause_menu_bw: Control = $PauseMenus/PauseMenuBW
@onready var crosshair: ColorRect = $Control/ColorRect
@onready var health_label: Label = $Control/HealthLabel
@onready var message_label: Label = $Control/MessageLabel
@onready var damage_flash: ColorRect = $Effects/DamageFlash

var _camera_start_position := Vector3.ZERO
var _camera_start_fov := 75.0
var _look_pitch := 0.0
var _turn_roll_input := 0.0
var _move_input := Vector2.ZERO
var _bob_time := 0.0
var _landing_kick := 0.0
var _was_on_floor := false
var _weapon_recoil_pitch := 0.0
var _weapon_recoil_yaw := 0.0
var _weapon_recoil_roll := 0.0
var _weapon_recoil_fov := 0.0
var _weapon_recoil_back := 0.0
var _weapon_recoil_kick_time := 0.0
var _weapon_shake_time := 0.0
var _weapon_shake_strength := 0.0
var _weapon_shake_phase := 0.0
var _shot_flash_alpha := 0.0
var _shot_concussion_strength := 0.0
var _shot_concussion_material: ShaderMaterial

var _dash_time_left := 0.0
var _dash_cooldown_left := 0.0
var _dash_direction := Vector3.ZERO
var _coyote_time_left := 0.0
var _jump_buffer_left := 0.0

const WEB_LEFT := 0
const WEB_RIGHT := 1
const WEB_RAYCAST_DISTANCE := 100000.0
var _web_states: Array[Dictionary] = [
	{
		"active": false,
		"anchor": Vector3.ZERO,
		"body": null,
		"local_anchor": Vector3.ZERO,
		"rope_length": 0.0,
		"visual_progress": 0.0,
		"visual_phase": 0.0,
		"launch_applied": false,
	},
	{
		"active": false,
		"anchor": Vector3.ZERO,
		"body": null,
		"local_anchor": Vector3.ZERO,
		"rope_length": 0.0,
		"visual_progress": 0.0,
		"visual_phase": 0.0,
		"launch_applied": false,
	},
]
var _web_lines: Array[MeshInstance3D] = []
var _web_anchor_markers: Array[MeshInstance3D] = []
var _web_audio_player: AudioStreamPlayer

var _headbutt_time := -1.0
var _headbutt_cooldown_left := 0.0
var _headbutt_has_hit := false
var _held_body: RigidBody3D = null
var _throw_direction := Vector3.FORWARD
var _suppress_attack_this_frame := false

var _black_white_mode := false
var _blink_timer := 0.0
var _blink_alpha := 0.0

var _message_time_left := 0.0
const _MESSAGE_DURATION := 3.0

var hp := 100.0
var _dead := false
var _damage_flash_alpha := 0.0
var _damage_audio_player: AudioStreamPlayer

var _step_player: AudioStreamPlayer
var _run_player: AudioStreamPlayer
var _dash_player: AudioStreamPlayer
var _headbutt_player: AudioStreamPlayer


func _ready() -> void:
	_camera_start_position = camera.position
	_camera_start_fov = camera.fov
	_look_pitch = camera.rotation.x
	_was_on_floor = is_on_floor()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gray_filter.visible = false
	blink_overlay.color.a = 0.0
	shot_flash.color.a = 0.0
	_create_shot_concussion_overlay()
	pause_menu_bw.visible = false
	_step_sound.loop = true
	_run_sound.loop = true
	_step_player = _create_audio_player("StepSound", _step_sound, footstep_volume_db)
	_run_player = _create_audio_player("RunSound", _run_sound, run_volume_db)
	_dash_player = _create_audio_player("DashSound", _dash_sound, dash_volume_db)
	_headbutt_player = _create_audio_player("HeadbuttSound", _headbutt_sound, headbutt_volume_db)
	_damage_audio_player = _create_audio_player(
		"DamageSound",
		_create_damage_sound(),
		damage_sound_volume_db
	)
	hp = max_hp
	if health_label:
		health_label.text = "%d / %d" % [int(hp), int(max_hp)]
	if damage_flash:
		damage_flash.color.a = 0.0
	_create_web_shooter()


func _input(event: InputEvent) -> void:
	weapon_manager.handle_input(event)

	if event.is_action_pressed("ui_cancel"):
		_open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_suppress_attack_this_frame = true
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := mouse_sensitivity
		if Input.is_physical_key_pressed(KEY_R):
			sensitivity *= aim_sensitivity_multiplier
		rotate_y(-event.relative.x * sensitivity)
		_look_pitch = clampf(
			_look_pitch - event.relative.y * sensitivity,
			-PI / 2.2,
			PI / 2.2
		)
		_turn_roll_input = clampf(
			_turn_roll_input - event.relative.x * 0.035,
			-turn_roll_degrees,
			turn_roll_degrees
		)


func _toggle_black_white_mode() -> void:
	_black_white_mode = not _black_white_mode
	gray_filter.visible = _black_white_mode
	_blink_timer = 0.0
	if not _black_white_mode:
		_blink_alpha = 0.0
		blink_overlay.color.a = 0.0
	weapon_manager.set_reload_speed(
		bw_reload_speed_multiplier if _black_white_mode else 1.0
	)
	weapon_manager.set_black_white_mode(_black_white_mode)
	var level := get_tree().current_scene
	if level:
		var dark_mode := level.get_node_or_null("DarkMode")
		if dark_mode and dark_mode.has_method("set_dark_mode"):
			dark_mode.set_dark_mode(_black_white_mode)


func _toggle_creative_mode() -> void:
	creative_mode = not creative_mode
	if creative_mode:
		print("КРЕАТИВ: включён — дальность паутины не ограничена, урон не наносится")
		_show_message("КРЕАТИВ: включён — дальность паутины не ограничена, урон не наносится")
	else:
		print("КРЕАТИВ: выключен — обычный режим")
		_show_message("КРЕАТИВ: выключен — обычный режим")


func _show_message(text: String) -> void:
	if message_label == null:
		return
	message_label.text = text
	message_label.modulate.a = 1.0
	message_label.visible = true
	_message_time_left = _MESSAGE_DURATION


func _update_blink(delta: float) -> void:
	if not _black_white_mode:
		return
	_blink_timer += delta
	if _blink_timer >= blink_interval:
		_blink_timer = 0.0
		_blink_alpha = blink_strength
	_blink_alpha = maxf(_blink_alpha - delta * blink_fade_speed, 0.0)
	blink_overlay.color.a = _blink_alpha


func _update_message(delta: float) -> void:
	if not message_label.visible:
		return
	_message_time_left -= delta
	if _message_time_left <= 0.0:
		message_label.visible = false
		return
	var fade_duration := 0.5
	if _message_time_left <= fade_duration:
		message_label.modulate.a = _message_time_left / fade_duration


func _open_pause_menu() -> void:
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _black_white_mode:
		pause_menu_bw.open()
	else:
		pause_menu.open()


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_floor_assistance(delta)
	_update_carry()

	_move_input = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var move_direction := (
		transform.basis * Vector3(_move_input.x, 0.0, _move_input.y)
	).normalized()
	_handle_web_input()

	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0 and not _has_active_web():
		_start_dash(move_direction)

	if _has_active_web():
		_update_web_swing(move_direction, delta)
	elif _dash_time_left > 0.0:
		var current_dash_speed := bw_dash_speed if _black_white_mode else dash_speed
		velocity.x = _dash_direction.x * current_dash_speed
		velocity.z = _dash_direction.z * current_dash_speed
	else:
		_update_horizontal_velocity(move_direction, delta)

	var vertical_speed_before_move := velocity.y
	var pre_velocity := velocity
	move_and_slide()
	_check_impact_damage(pre_velocity)

	if not _was_on_floor and is_on_floor():
		_landing_kick = clampf(absf(vertical_speed_before_move) * 0.012, 0.0, 0.085)
	_was_on_floor = is_on_floor()
	_update_footstep_sounds(delta)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not _suppress_attack_this_frame:
		if not weapon_manager.is_web_shooter_selected() and weapon_manager.play_attack():
			_perform_attack()
	if Input.is_action_just_pressed("strong_attack"):
		if _headbutt_time < 0.0 and not _try_grab():
			_start_headbutt()
	if Input.is_action_just_released("strong_attack"):
		_release_throw()
	if Input.is_action_just_pressed("black_white"):
		_toggle_black_white_mode()
	if Input.is_action_just_pressed("toggle_creative"):
		_toggle_creative_mode()
	_update_blink(delta)
	_update_message(delta)
	_update_shot_flash(delta)
	_update_damage_flash(delta)
	_suppress_attack_this_frame = false

	var headbutt_pose := _update_headbutt(delta)
	_update_camera(delta, headbutt_pose)
	_update_web_visual(delta)


func apply_weapon_recoil(strength: float, weapon_index := 0) -> void:
	var shotgun_multiplier := 1.18 if weapon_index == 0 else 1.0
	_weapon_recoil_pitch = minf(
		_weapon_recoil_pitch + deg_to_rad(8.5) * strength * shotgun_multiplier,
		deg_to_rad(14.0)
	)
	_weapon_recoil_yaw += deg_to_rad(randf_range(-2.0, 2.0)) * strength
	_weapon_recoil_roll += deg_to_rad(randf_range(-2.4, 2.4)) * strength
	_weapon_recoil_fov = maxf(_weapon_recoil_fov, 4.6 * strength)
	_weapon_recoil_back = maxf(_weapon_recoil_back, 0.065 * strength * shotgun_multiplier)
	_weapon_recoil_kick_time = maxf(_weapon_recoil_kick_time, 0.085)
	_weapon_shake_time = maxf(_weapon_shake_time, 0.16 + 0.16 * strength)
	_weapon_shake_strength = maxf(_weapon_shake_strength, 0.062 * strength)
	_shot_flash_alpha = maxf(_shot_flash_alpha, 0.52 * strength)
	_shot_concussion_strength = maxf(_shot_concussion_strength, 0.72 * strength)


func _create_shot_concussion_overlay() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 radial = SCREEN_UV - vec2(0.5);
	float distance_from_center = length(radial);
	float split = strength * 0.009 * (1.0 - smoothstep(0.1, 0.75, distance_from_center));
	vec2 offset = radial * split;
	vec3 color;
	color.r = texture(screen_texture, SCREEN_UV + offset).r;
	color.g = texture(screen_texture, SCREEN_UV).g;
	color.b = texture(screen_texture, SCREEN_UV - offset).b;
	float edge = smoothstep(0.18, 0.72, distance_from_center);
	color *= 1.0 - edge * strength * 0.42;
	color += vec3(1.0, 0.62, 0.24) * strength * (1.0 - edge) * 0.16;
	COLOR = vec4(color, 1.0);
}
"""
	_shot_concussion_material = ShaderMaterial.new()
	_shot_concussion_material.shader = shader
	_shot_concussion_material.set_shader_parameter("strength", 0.0)
	var overlay := ColorRect.new()
	overlay.name = "ShotConcussion"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.material = _shot_concussion_material
	$Effects.add_child(overlay)
	$Effects.move_child(overlay, shot_flash.get_index())


func _update_shot_flash(delta: float) -> void:
	if _black_white_mode:
		_shot_flash_alpha = 0.0
		_shot_concussion_strength = 0.0
		shot_flash.color.a = 0.0
		_shot_concussion_material.set_shader_parameter("strength", 0.0)
		return
	_shot_flash_alpha = maxf(_shot_flash_alpha - delta * 3.2, 0.0)
	_shot_concussion_strength = maxf(_shot_concussion_strength - delta * 4.6, 0.0)
	_shot_concussion_material.set_shader_parameter(
		"strength",
		_shot_concussion_strength
	)
	shot_flash.color = Color(
		1.0,
		1.0 if _black_white_mode else 0.92,
		1.0 if _black_white_mode else 0.7,
		_shot_flash_alpha
	)


func _check_impact_damage(pre_velocity: Vector3) -> void:
	if _dead:
		return
	var max_approach := 0.0
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		var collider_velocity := collision.get_collider_velocity()
		var collider := collision.get_collider()
		if normal.y < 0.5 and not collider is RigidBody3D:
			continue
		var approach_speed := (collider_velocity - pre_velocity).dot(normal)
		max_approach = maxf(max_approach, approach_speed)
	if max_approach < impact_damage_threshold:
		return
	var damage := (max_approach - impact_damage_threshold) * impact_damage_multiplier
	take_damage(damage)


func take_damage(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	if creative_mode:
		print("КРЕАТИВ: получен урон %.1f, но в креативе здоровье не меняется" % amount)
		return
	hp = maxf(hp - amount, 0.0)
	_damage_flash_alpha = clampf(
		_damage_flash_alpha + amount * damage_flash_intensity,
		0.0,
		0.8
	)
	if _damage_audio_player:
		_damage_audio_player.pitch_scale = randf_range(0.9, 1.05)
		_damage_audio_player.play()
	if health_label:
		health_label.text = "%d / %d" % [int(ceilf(hp)), int(max_hp)]
	if hp <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	_damage_flash_alpha = 0.8
	_release_all_webs(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().call_deferred("reload_current_scene")


func _update_damage_flash(delta: float) -> void:
	if not damage_flash:
		return
	_damage_flash_alpha = maxf(
		_damage_flash_alpha - delta * damage_flash_decay,
		0.0
	)
	damage_flash.color.a = clampf(_damage_flash_alpha, 0.0, 0.8)


func _create_damage_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := int(stream.mix_rate * 0.25)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	for sample_index in sample_count:
		var progress := float(sample_index) / float(sample_count)
		var frequency := lerpf(160.0, 45.0, progress)
		phase += TAU * frequency / float(stream.mix_rate)
		var envelope := (1.0 - progress) * (1.0 - progress)
		var value := clampf(sin(phase) * envelope, -1.0, 1.0)
		data.encode_s16(sample_index * 2, int(value * 22000.0))
	stream.data = data
	return stream


func _update_timers(delta: float) -> void:
	_dash_time_left = maxf(_dash_time_left - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_headbutt_cooldown_left = maxf(_headbutt_cooldown_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = jump_buffer_time


func _update_floor_assistance(delta: float) -> void:
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.55

	if is_on_floor():
		_coyote_time_left = coyote_time
	else:
		_coyote_time_left = maxf(_coyote_time_left - delta, 0.0)
		velocity += get_gravity() * delta

	if _jump_buffer_left > 0.0 and _coyote_time_left > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_left = 0.0
		_coyote_time_left = 0.0


func _create_web_shooter() -> void:
	var web_material := StandardMaterial3D.new()
	web_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	web_material.albedo_color = Color(0.88, 0.95, 1.0, 1.0)
	web_material.emission_enabled = true
	web_material.emission = Color(0.18, 0.38, 0.58)
	web_material.emission_energy_multiplier = 0.85
	web_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.035
	marker_mesh.height = 0.07
	marker_mesh.material = web_material
	for side in 2:
		var line_mesh := ImmediateMesh.new()
		var line := MeshInstance3D.new()
		line.name = "LeftWebLine" if side == WEB_LEFT else "RightWebLine"
		line.mesh = line_mesh
		line.layers = 2
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		line.visible = false
		weapon_manager.add_child(line)
		line.top_level = true
		_web_lines.append(line)

		var marker := MeshInstance3D.new()
		marker.name = "LeftWebAnchor" if side == WEB_LEFT else "RightWebAnchor"
		marker.mesh = marker_mesh
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marker.visible = false
		add_child(marker)
		marker.top_level = true
		_web_anchor_markers.append(marker)

	_web_audio_player = AudioStreamPlayer.new()
	_web_audio_player.name = "WebShooterSound"
	_web_audio_player.stream = _create_web_sound()
	_web_audio_player.volume_db = -4.0
	_web_audio_player.max_polyphony = 4
	add_child(_web_audio_player)


func _create_web_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := int(stream.mix_rate * 0.14)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	for sample_index in sample_count:
		var progress := float(sample_index) / float(sample_count)
		var frequency := lerpf(920.0, 210.0, progress)
		phase += TAU * frequency / float(stream.mix_rate)
		var envelope := sin(PI * progress) * (1.0 - progress * 0.45)
		var noise := randf_range(-0.13, 0.13) * (1.0 - progress)
		var value := clampf((sin(phase) * 0.72 + noise) * envelope, -1.0, 1.0)
		data.encode_s16(sample_index * 2, int(value * 19000.0))
	stream.data = data
	return stream


func _handle_web_input() -> void:
	if not weapon_manager.is_web_shooter_selected():
		if _has_active_web():
			_release_all_webs(false)
		crosshair.color = crosshair.color.lerp(
			Color(1.0, 1.0, 1.0, 0.6235),
			0.18
		)
		return

	_handle_web_side_input(WEB_LEFT, "attack")
	_handle_web_side_input(WEB_RIGHT, "web_swing")
	if _has_active_web() and Input.is_action_just_pressed("jump"):
		_release_all_webs(true)
	if not _has_active_web():
		crosshair.color = crosshair.color.lerp(
			Color(1.0, 1.0, 1.0, 0.6235),
			0.18
		)


func _handle_web_side_input(side: int, action: StringName) -> void:
	if Input.is_action_just_pressed(action):
		var hit := _find_web_anchor(side)
		if hit.is_empty():
			crosshair.color = Color(1.0, 0.28, 0.22, 0.9)
		else:
			_attach_web(hit, side)
	elif Input.is_action_just_released(action):
		_release_web(side, false)


func _has_active_web() -> bool:
	return bool(_web_states[WEB_LEFT]["active"]) or bool(
		_web_states[WEB_RIGHT]["active"]
	)


func _find_web_anchor(side := WEB_LEFT) -> Dictionary:
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	var up := camera.global_basis.y
	var right := camera.global_basis.x
	var side_sign := -1.0 if side == WEB_LEFT else 1.0
	var direct_hit := _raycast_web_anchor(origin, forward)
	if _is_valid_web_anchor(direct_hit):
		return direct_hit

	var search_offsets: Array[Vector2] = [
		Vector2(0.0, 0.12),
		Vector2(side_sign * 0.1, 0.1),
		Vector2(-side_sign * 0.1, 0.12),
		Vector2(side_sign * 0.2, 0.16),
		Vector2(-side_sign * 0.2, 0.18),
		Vector2(0.0, 0.25),
		Vector2(side_sign * 0.32, 0.23),
		Vector2(-side_sign * 0.32, 0.25),
		Vector2(side_sign * 0.42, 0.3),
		Vector2(-side_sign * 0.42, 0.3),
	]
	var best_hit: Dictionary = {}
	var best_score := -INF
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var travel_direction := (
		horizontal_velocity.normalized()
		if horizontal_velocity.length() > sprint_speed
		else Vector3(forward.x, 0.0, forward.z).normalized()
	)
	for offset in search_offsets:
		var direction := (forward + right * offset.x + up * offset.y).normalized()
		var hit := _raycast_web_anchor(origin, direction)
		if not _is_valid_web_anchor(hit):
			continue
		var point: Vector3 = hit.position
		var height := point.y - global_position.y
		var horizontal_direction := Vector3(direction.x, 0.0, direction.z).normalized()
		var center_proximity := 1.0 - clampf(offset.length() / 0.52, 0.0, 1.0)
		var score := (
			center_proximity * 5.0
			+ direction.dot(forward) * 1.5
			+ clampf(height / 25.0, -1.0, 1.0) * 0.35
			+ horizontal_direction.dot(travel_direction) * 0.25
			+ maxf(offset.x * side_sign, 0.0) * 0.12
		)
		if score > best_score:
			best_score = score
			best_hit = hit
	return best_hit


func _raycast_web_anchor(origin: Vector3, direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * _get_web_raycast_distance()
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query)


func _get_web_raycast_distance() -> float:
	if creative_mode:
		return WEB_RAYCAST_DISTANCE
	return web_range


func _is_web_anchor_behind_camera(anchor: Vector3) -> bool:
	var to_anchor := anchor - camera.global_position
	if to_anchor.length_squared() < 0.0001:
		return false
	return to_anchor.normalized().dot(-camera.global_basis.z) < 0.0


func _is_valid_web_anchor(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	if _is_web_anchor_behind_camera(hit.position):
		return false
	if hit.collider is StaticBody3D:
		var point: Vector3 = hit.position
		var minimum_height := web_min_anchor_height if is_on_floor() else -web_air_anchor_drop
		return point.y - global_position.y >= minimum_height
	return _find_glow_rigid_body(hit.collider) != null


func _find_glow_rigid_body(collider: Node) -> RigidBody3D:
	var node: Node = collider
	while node:
		if node.is_in_group("glow_body"):
			return node as RigidBody3D
		node = node.get_parent()
	return null


func _attach_web(hit: Dictionary, side := WEB_LEFT) -> void:
	var glow_body := _find_glow_rigid_body(hit.collider)
	if glow_body:
		_pull_glow_body(glow_body, side)
		return
	var state := _web_states[side]
	var anchor: Vector3 = hit.position
	var anchor_body := hit.collider as Node3D
	state["anchor"] = anchor
	state["body"] = anchor_body
	state["local_anchor"] = (
		anchor_body.to_local(anchor) if anchor_body else Vector3.ZERO
	)
	var distance := global_position.distance_to(anchor)
	var desired_rope_length := distance * web_rope_slack
	if is_on_floor():
		var anchor_height := maxf(
			anchor.y - global_position.y,
			web_min_rope_length
		)
		desired_rope_length = minf(
			desired_rope_length,
			anchor_height * 1.25
		)
	state["rope_length"] = maxf(desired_rope_length, web_min_rope_length)
	state["active"] = true
	state["visual_progress"] = 0.0
	state["visual_phase"] = randf_range(0.0, TAU)
	state["launch_applied"] = false
	_web_states[side] = state
	_dash_time_left = 0.0
	crosshair.color = Color(0.38, 0.9, 1.0, 1.0)
	_web_lines[side].visible = true
	_web_anchor_markers[side].visible = true
	if _web_audio_player:
		_web_audio_player.pitch_scale = randf_range(0.94, 1.02) if side == WEB_LEFT else randf_range(1.04, 1.12)
		_web_audio_player.play()


func _apply_web_attach_launch(side: int) -> void:
	var state := _web_states[side]
	if bool(state["launch_applied"]):
		return
	var anchor: Vector3 = state["anchor"]
	var pull_direction := (anchor - global_position).normalized()
	velocity += pull_direction * web_attach_pull
	var launch_direction := (-camera.global_basis.z).slide(pull_direction)
	if launch_direction.length_squared() < 0.01:
		launch_direction = velocity.slide(pull_direction)
	if launch_direction.length_squared() < 0.01:
		launch_direction = pull_direction.cross(camera.global_basis.x)
	launch_direction = (launch_direction.normalized() + Vector3.UP * 0.22).normalized()
	velocity += launch_direction * web_attach_launch
	if is_on_floor():
		velocity.y = maxf(velocity.y, jump_velocity * 1.15)
	state["launch_applied"] = true
	_web_states[side] = state


func _pull_glow_body(glow_body: RigidBody3D, side: int) -> void:
	var pull_direction := (global_position - glow_body.global_position).normalized()
	var delta_velocity := pull_direction * web_glow_pull_speed - glow_body.linear_velocity
	glow_body.apply_central_impulse(delta_velocity * glow_body.mass)
	crosshair.color = Color(1.0, 1.0, 1.0, 1.0)
	if _web_audio_player:
		_web_audio_player.pitch_scale = (
			randf_range(1.1, 1.3) if side == WEB_LEFT else randf_range(1.3, 1.5)
		)
		_web_audio_player.play()


func _webs_fully_attached() -> bool:
	for side in 2:
		if bool(_web_states[side]["active"]) and float(_web_states[side]["visual_progress"]) < 1.0:
			return false
	return true


func _release_web(side: int, boosted := false) -> void:
	var state := _web_states[side]
	if not bool(state["active"]):
		return
	state["active"] = false
	state["body"] = null
	_web_states[side] = state
	var line_mesh := _web_lines[side].mesh as ImmediateMesh
	line_mesh.clear_surfaces()
	_web_lines[side].visible = false
	_web_anchor_markers[side].visible = false
	if boosted:
		_apply_web_release_boost()


func _release_all_webs(boosted: bool) -> void:
	var had_active_web := _has_active_web()
	for side in 2:
		_release_web(side, false)
	if boosted and had_active_web:
		_apply_web_release_boost()
	crosshair.color = Color(1.0, 1.0, 1.0, 0.6235)


func _apply_web_release_boost() -> void:
	var forward := -camera.global_transform.basis.z
	var momentum_direction := velocity.normalized() if velocity.length_squared() > 0.01 else forward
	var launch_direction := (
		momentum_direction * 0.72 + forward * 0.28 + Vector3.UP * 0.3
	).normalized()
	velocity += launch_direction * web_release_boost
	if velocity.length() > web_max_speed:
		velocity = velocity.normalized() * web_max_speed
	if _web_audio_player:
		_web_audio_player.pitch_scale = 1.32
		_web_audio_player.play()


func _refresh_web_anchor(side: int) -> bool:
	var state := _web_states[side]
	var anchor_body := state["body"] as Node3D
	if anchor_body == null:
		return true
	if not is_instance_valid(anchor_body):
		_release_web(side, false)
		return false
	state["anchor"] = anchor_body.to_global(state["local_anchor"])
	_web_states[side] = state
	return true


func _update_web_swing(move_direction: Vector3, delta: float) -> void:
	if not _webs_fully_attached():
		_update_horizontal_velocity(move_direction, delta)
		return
	for side in 2:
		if bool(_web_states[side]["active"]):
			_apply_web_attach_launch(side)
	var active_sides: Array[int] = []
	var combined_radial := Vector3.ZERO
	for side in 2:
		if not bool(_web_states[side]["active"]) or not _refresh_web_anchor(side):
			continue
		var anchor: Vector3 = _web_states[side]["anchor"]
		var to_anchor := anchor - global_position
		var distance := to_anchor.length()
		if distance < 0.01 or _is_web_anchor_behind_camera(anchor):
			_release_web(side, false)
			continue
		active_sides.append(side)
		combined_radial += to_anchor / distance
	if active_sides.is_empty():
		return
	var radial_direction := combined_radial.normalized()
	var camera_forward_tangent := (-camera.global_basis.z).slide(radial_direction)
	if camera_forward_tangent.length_squared() < 0.01:
		camera_forward_tangent = velocity.slide(radial_direction)
	if camera_forward_tangent.length_squared() < 0.01:
		camera_forward_tangent = radial_direction.cross(camera.global_basis.x)
	camera_forward_tangent = camera_forward_tangent.normalized()
	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0:
		var dash_tangent := velocity.slide(radial_direction)
		if dash_tangent.length_squared() < 0.01:
			dash_tangent = (-camera.global_transform.basis.z).slide(radial_direction)
		if dash_tangent.length_squared() > 0.01:
			velocity += dash_tangent.normalized() * dash_speed * 0.65
			_dash_cooldown_left = dash_cooldown
			if _dash_player:
				_dash_player.play()
	var tangent_input := move_direction.slide(radial_direction)
	if tangent_input.length_squared() > 0.001:
		velocity += tangent_input.normalized() * web_steer_acceleration * delta

	var tangent_velocity := velocity.slide(radial_direction)
	var tangent_speed := tangent_velocity.length()
	var wants_to_brake := _move_input.y > 0.2
	if not wants_to_brake:
		var speed_deficit := maxf(web_cruise_speed - tangent_speed, 0.0)
		var assisted_acceleration := web_forward_assist + speed_deficit * 2.0
		velocity += camera_forward_tangent * assisted_acceleration * delta
	else:
		velocity -= tangent_velocity * minf(delta * 1.8, 0.3)

	for side in active_sides:
		var state := _web_states[side]
		var anchor: Vector3 = state["anchor"]
		var to_anchor := anchor - global_position
		var distance := to_anchor.length()
		var side_radial := to_anchor / distance
		var rope_length: float = state["rope_length"]
		var minimum_length := maxf(web_min_rope_length, distance * 0.55)
		if _move_input.y < -0.2:
			rope_length = maxf(rope_length - web_reel_speed * delta, minimum_length)
		elif wants_to_brake:
			rope_length = minf(
				rope_length + web_extend_speed * delta,
				distance * 1.08
			)
		state["rope_length"] = rope_length
		_web_states[side] = state
		var tension_start := rope_length * 0.9
		if distance > tension_start:
			var stretch := maxf(distance - rope_length, 0.0)
			var tension_amount := clampf(
				(distance - tension_start) / maxf(rope_length * 0.1, 0.01),
				0.0,
				1.0
			)
			var away_speed := velocity.dot(-side_radial)
			if away_speed > 0.0:
				velocity += side_radial * away_speed * minf(
					web_radial_damping * delta,
					1.0
				)
			velocity += side_radial * (
				web_tension * tension_amount + stretch * web_spring_strength
			) * delta

	velocity *= maxf(1.0 - web_air_drag * delta, 0.0)
	if velocity.length() > web_max_speed:
		velocity = velocity.normalized() * web_max_speed


func _get_web_hand_position(side: int) -> Vector3:
	return weapon_manager.get_web_origin_global_position(side)


func _update_web_visual(delta: float) -> void:
	for side in 2:
		if not bool(_web_states[side]["active"]) or not _refresh_web_anchor(side):
			continue
		var state := _web_states[side]
		var line_start := _get_web_hand_position(side)
		var anchor: Vector3 = state["anchor"]
		var full_length := camera.global_position.distance_to(anchor)
		if full_length < 0.05:
			continue
		state["visual_progress"] = minf(
			float(state["visual_progress"]) + web_shot_speed * delta / full_length,
			1.0
		)
		state["visual_phase"] = fmod(float(state["visual_phase"]) + delta * 3.2, TAU)
		_web_states[side] = state
		var root_viewport_size := Vector2(get_viewport().get_visible_rect().size)
		var anchor_uv := camera.unproject_position(anchor) / root_viewport_size
		var visual_target: Vector3 = weapon_manager.get_web_visual_target(
			anchor_uv,
			web_visual_depth
		)
		var visible_anchor := line_start.lerp(
			visual_target,
			_smoothstep(float(state["visual_progress"]))
		)
		var points := _build_web_curve(
			line_start,
			visible_anchor,
			state,
			side
		)
		var line_mesh := _web_lines[side].mesh as ImmediateMesh
		_build_web_mesh(
			line_mesh,
			points,
			line_start,
			float(state["visual_phase"]),
			side
		)
		_web_lines[side].global_transform = Transform3D(Basis.IDENTITY, line_start)
		_web_anchor_markers[side].global_position = anchor
		var marker_scale := lerpf(0.15, 1.0, float(state["visual_progress"]))
		_web_anchor_markers[side].scale = Vector3.ONE * marker_scale


func _build_web_curve(
	line_start: Vector3,
	visible_anchor: Vector3,
	state: Dictionary,
	side: int
) -> PackedVector3Array:
	var points := PackedVector3Array()
	var relative_end := visible_anchor - line_start
	var distance := relative_end.length()
	var segment_count := maxi(web_visual_segments, 6)
	var launch_amount := 1.0 - float(state["visual_progress"])
	var sag := clampf(distance * 0.025, 0.012, 0.12)
	var side_sign := -1.0 if side == WEB_LEFT else 1.0
	var viewmodel_camera: Camera3D = weapon_manager.get_viewmodel_camera()
	var lateral := viewmodel_camera.global_basis.x * side_sign
	for point_index in range(segment_count + 1):
		var t := float(point_index) / float(segment_count)
		var point := relative_end * t
		var envelope := sin(PI * t)
		point.y -= sag * envelope
		point += lateral * (
			sin(t * TAU * 2.0 + float(state["visual_phase"]))
			* envelope
			* launch_amount
			* 0.12
		)
		points.append(point)
	return points


func _build_web_mesh(
	mesh: ImmediateMesh,
	core_points: PackedVector3Array,
	line_start: Vector3,
	phase: float,
	side: int
) -> void:
	mesh.clear_surfaces()
	if core_points.size() < 2:
		return
	var web_material := (_web_anchor_markers[side].mesh as SphereMesh).material
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, web_material)
	_append_web_ribbon(mesh, core_points, line_start, web_visual_pixel_width)
	for strand_index in 2:
		var strand_points := PackedVector3Array()
		for point_index in core_points.size():
			var tangent := _web_curve_tangent(core_points, point_index)
			var frame := _web_curve_frame(tangent)
			var t := float(point_index) / float(core_points.size() - 1)
			var angle := t * TAU * 9.0 + phase + PI * float(strand_index)
			var offset := (
				frame[0] * cos(angle) + frame[1] * sin(angle)
			) * 0.006
			strand_points.append(core_points[point_index] + offset)
		_append_web_ribbon(
			mesh,
			strand_points,
			line_start,
			web_visual_pixel_width * 0.38
		)
	mesh.surface_end()


func _append_web_ribbon(
	mesh: ImmediateMesh,
	points: PackedVector3Array,
	line_start: Vector3,
	pixel_width: float
) -> void:
	var viewmodel_camera: Camera3D = weapon_manager.get_viewmodel_camera()
	var viewport_height := maxf(
		float(viewmodel_camera.get_viewport().get_visible_rect().size.y),
		1.0
	)
	for point_index in range(points.size() - 1):
		var tangent_a := _web_curve_tangent(points, point_index)
		var tangent_b := _web_curve_tangent(points, point_index + 1)
		var global_a := line_start + points[point_index]
		var global_b := line_start + points[point_index + 1]
		var view_a := (viewmodel_camera.global_position - global_a).normalized()
		var view_b := (viewmodel_camera.global_position - global_b).normalized()
		var side_a := tangent_a.cross(view_a).normalized()
		var side_b := tangent_b.cross(view_b).normalized()
		if side_a.length_squared() < 0.001:
			side_a = viewmodel_camera.global_basis.x
		if side_b.length_squared() < 0.001:
			side_b = viewmodel_camera.global_basis.x
		var width_a := _web_world_half_width(
			viewmodel_camera,
			global_a,
			viewport_height,
			pixel_width
		)
		var width_b := _web_world_half_width(
			viewmodel_camera,
			global_b,
			viewport_height,
			pixel_width
		)
		var normal := (view_a + view_b).normalized()
		_add_web_vertex(mesh, points[point_index] - side_a * width_a, normal)
		_add_web_vertex(mesh, points[point_index + 1] - side_b * width_b, normal)
		_add_web_vertex(mesh, points[point_index + 1] + side_b * width_b, normal)
		_add_web_vertex(mesh, points[point_index] - side_a * width_a, normal)
		_add_web_vertex(mesh, points[point_index + 1] + side_b * width_b, normal)
		_add_web_vertex(mesh, points[point_index] + side_a * width_a, normal)


func _web_world_half_width(
	viewmodel_camera: Camera3D,
	global_point: Vector3,
	viewport_height: float,
	pixel_width: float
) -> float:
	var camera_point := viewmodel_camera.to_local(global_point)
	var depth := maxf(-camera_point.z, viewmodel_camera.near)
	var world_height := 2.0 * depth * tan(deg_to_rad(viewmodel_camera.fov) * 0.5)
	return world_height / viewport_height * pixel_width * 0.5


func _add_web_vertex(mesh: ImmediateMesh, position: Vector3, normal: Vector3) -> void:
	mesh.surface_set_normal(normal)
	mesh.surface_add_vertex(position)


func _web_curve_tangent(points: PackedVector3Array, point_index: int) -> Vector3:
	var previous_index := maxi(point_index - 1, 0)
	var next_index := mini(point_index + 1, points.size() - 1)
	var tangent := points[next_index] - points[previous_index]
	return tangent.normalized() if tangent.length_squared() > 0.000001 else Vector3.FORWARD


func _web_curve_frame(tangent: Vector3) -> Array[Vector3]:
	var side_axis := tangent.cross(Vector3.UP)
	if side_axis.length_squared() < 0.0001:
		side_axis = tangent.cross(Vector3.RIGHT)
	side_axis = side_axis.normalized()
	return [side_axis, side_axis.cross(tangent).normalized()]


func _get_web_focus_anchor() -> Vector3:
	var anchor_sum := Vector3.ZERO
	var anchor_count := 0
	for side in 2:
		if bool(_web_states[side]["active"]):
			anchor_sum += _web_states[side]["anchor"]
			anchor_count += 1
	return anchor_sum / float(anchor_count) if anchor_count > 0 else global_position


func _create_audio_player(
	player_name: String,
	stream: AudioStream,
	volume_db: float
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player


func _update_footstep_sounds(_delta: float) -> void:
	var moving_on_floor := (
		is_on_floor()
		and _dash_time_left <= 0.0
		and Vector2(velocity.x, velocity.z).length() > 0.5
	)
	if moving_on_floor:
		var is_sprinting := (
			_black_white_mode
			or (Input.is_action_pressed("sprint") and _move_input.y < 0.0)
		)
		if is_sprinting:
			if _run_player and not _run_player.playing:
				_run_player.play()
			if _step_player and _step_player.playing:
				_step_player.stop()
		else:
			if _step_player and not _step_player.playing:
				_step_player.play()
			if _run_player and _run_player.playing:
				_run_player.stop()
	else:
		_stop_footstep_sounds()


func _stop_footstep_sounds() -> void:
	if _step_player:
		_step_player.stop()
	if _run_player:
		_run_player.stop()


func _start_dash(move_direction: Vector3) -> void:
	_dash_direction = move_direction
	if _dash_direction == Vector3.ZERO:
		_dash_direction = -transform.basis.z

	_dash_direction.y = 0.0
	_dash_direction = _dash_direction.normalized()
	_dash_time_left = bw_dash_duration if _black_white_mode else dash_duration
	_dash_cooldown_left = dash_cooldown
	if _dash_player:
		_dash_player.play()


func _update_horizontal_velocity(move_direction: Vector3, delta: float) -> void:
	var target_speed: float
	if _black_white_mode:
		target_speed = sprint_speed * bw_speed_multiplier
	else:
		target_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := move_direction * target_speed
	var current_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var acceleration := ground_acceleration

	if not is_on_floor():
		acceleration = air_acceleration
	elif move_direction == Vector3.ZERO:
		acceleration = ground_deceleration

	current_horizontal = current_horizontal.move_toward(target_velocity, acceleration * delta)
	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.z


func _start_headbutt() -> void:
	if _headbutt_cooldown_left > 0.0 or _headbutt_time >= 0.0:
		return

	_headbutt_time = 0.0
	_headbutt_cooldown_left = headbutt_cooldown
	_headbutt_has_hit = false


func _try_grab() -> bool:
	if not ray.is_colliding():
		return false
	var body := ray.get_collider()
	if body == null:
		return false
	var hit_point := ray.get_collision_point()
	if global_position.distance_to(hit_point) > close_distance:
		return false
	var rigid_body := body as RigidBody3D
	if rigid_body == null:
		return false
	_held_body = rigid_body
	_headbutt_has_hit = false
	return true


func _release_throw() -> void:
	if _held_body == null or _headbutt_time >= 0.0:
		return
	_throw_direction = -camera.global_transform.basis.z
	_headbutt_time = 0.0
	_headbutt_cooldown_left = headbutt_cooldown
	_headbutt_has_hit = false


func _update_carry() -> void:
	if _held_body == null or not is_instance_valid(_held_body):
		_held_body = null
		return
	if _headbutt_has_hit:
		_held_body = null
		return
	var target := camera.global_position + -camera.global_transform.basis.z * hold_distance
	target.y += hold_lift
	var carry_velocity := (target - _held_body.global_position) * carry_speed
	if carry_velocity.length() > 20.0:
		carry_velocity = carry_velocity.normalized() * 20.0
	_held_body.linear_velocity = carry_velocity
	var yaw_diff := wrapf(_held_body.global_rotation.y - camera.global_rotation.y, -PI, PI)
	_held_body.angular_velocity = Vector3(0.0, -yaw_diff * carry_rot_speed, 0.0)


func _update_headbutt(delta: float) -> Vector3:
	if _headbutt_time < 0.0:
		return Vector3.ZERO

	_headbutt_time += delta
	var progress := clampf(_headbutt_time / headbutt_duration, 0.0, 1.0)

	if not _headbutt_has_hit and progress >= 0.52:
		if _perform_attack(true, _black_white_mode) and _headbutt_player:
			_headbutt_player.play()
		_headbutt_has_hit = true

	var height_offset := 0.0
	var forward_offset := 0.0
	var pitch_offset := 0.0

	if progress < 0.38:
		var anticipation := _smoothstep(progress / 0.38)
		height_offset = lerpf(0.0, headbutt_lift, anticipation)
		forward_offset = lerpf(0.0, headbutt_windup_back, anticipation)
		pitch_offset = deg_to_rad(headbutt_windup_tilt_degrees) * anticipation
	elif progress < 0.52:
		var strike := _smoothstep((progress - 0.38) / 0.14)
		height_offset = lerpf(headbutt_lift, -headbutt_drop, strike)
		forward_offset = lerpf(headbutt_windup_back, -headbutt_reach, strike)
		pitch_offset = lerpf(
			deg_to_rad(headbutt_windup_tilt_degrees),
			deg_to_rad(-headbutt_tilt_degrees),
			strike
		)
	else:
		var recovery := _smoothstep((progress - 0.52) / 0.48)
		height_offset = lerpf(-headbutt_drop, 0.0, recovery)
		forward_offset = lerpf(-headbutt_reach, 0.0, recovery)
		pitch_offset = lerpf(deg_to_rad(-headbutt_tilt_degrees), 0.0, recovery)

	if progress >= 1.0:
		_headbutt_time = -1.0
		_headbutt_has_hit = false

	return Vector3(height_offset, forward_offset, pitch_offset)


func _perform_attack(close_only := false, use_close_power := true) -> bool:
	var power_multiplier := close_multiplier if use_close_power else 1.0
	if _held_body != null:
		var thrown := _held_body
		_held_body = null
		var throw_impulse := _throw_direction * impulse * power_multiplier
		var horizontal_amount := 1.0 - absf(_throw_direction.y)
		throw_impulse.y += thrown.mass * headbutt_upward_velocity * horizontal_amount
		thrown.apply_central_impulse(throw_impulse)
		if "hp" in thrown:
			thrown.hp = 0
		return true

	if not ray.is_colliding():
		return false

	var body := ray.get_collider()
	if body == null:
		return false

	var hit_point := ray.get_collision_point()
	var distance_to_hit := global_position.distance_to(hit_point)
	if close_only and distance_to_hit > close_distance:
		return false
	var attack_power := impulse
	if use_close_power and distance_to_hit <= close_distance:
		attack_power *= close_multiplier

	var hit_direction := hit_point - global_position
	if hit_direction.length_squared() < 0.001:
		hit_direction = -camera.global_transform.basis.z
	hit_direction = hit_direction.normalized()

	var rigid_body := body as RigidBody3D
	if rigid_body:
		var impulse_vector := hit_direction * attack_power
		if close_only:
			impulse_vector.y += rigid_body.mass * headbutt_upward_velocity
		rigid_body.apply_central_impulse(impulse_vector)

	if "hp" in body:
		body.hp = 0
	return true


func _update_camera(delta: float, headbutt_pose: Vector3) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clampf(horizontal_speed / sprint_speed, 0.0, 1.0)
	var is_moving_on_floor := is_on_floor() and horizontal_speed > 0.15

	if is_moving_on_floor:
		_bob_time += delta * bob_frequency * lerpf(1.0, 1.55, speed_ratio)
	else:
		_bob_time = lerpf(_bob_time, 0.0, _exp_weight(8.0, delta))

	var bob_amount := lerpf(walk_bob_amount, sprint_bob_amount, speed_ratio)
	var bob_offset := Vector3.ZERO
	if is_moving_on_floor:
		bob_offset.x = cos(_bob_time * PI) * bob_amount * 0.45
		bob_offset.y = sin(_bob_time * TAU) * bob_amount

	_weapon_shake_time = maxf(_weapon_shake_time - delta, 0.0)
	_weapon_recoil_kick_time = maxf(_weapon_recoil_kick_time - delta, 0.0)
	_weapon_shake_phase += delta * 94.0
	var shake_ratio := clampf(_weapon_shake_time / 0.32, 0.0, 1.0)
	var shake_offset := Vector3.ZERO
	var shake_rotation := Vector3.ZERO
	if _weapon_shake_time > 0.0:
		shake_offset = Vector3(
			sin(_weapon_shake_phase * 1.7),
			cos(_weapon_shake_phase * 2.3),
			0.0
		) * _weapon_shake_strength * shake_ratio
		shake_rotation = Vector3(
			sin(_weapon_shake_phase * 2.1),
			cos(_weapon_shake_phase * 1.4),
			sin(_weapon_shake_phase * 2.8)
		) * _weapon_shake_strength * 0.55 * shake_ratio

	_landing_kick = lerpf(_landing_kick, 0.0, _exp_weight(12.0, delta))
	_turn_roll_input = lerpf(_turn_roll_input, 0.0, _exp_weight(10.0, delta))

	var strafe_roll := -_move_input.x * strafe_roll_degrees * speed_ratio
	var target_roll := deg_to_rad(strafe_roll + _turn_roll_input)
	if _has_active_web():
		var focus_anchor := _get_web_focus_anchor()
		var local_anchor_direction := camera.global_transform.basis.inverse() * (
			focus_anchor - camera.global_position
		).normalized()
		target_roll += deg_to_rad(web_camera_roll_degrees) * clampf(
			-local_anchor_direction.x,
			-1.0,
			1.0
		)
	var target_position := _camera_start_position + bob_offset + shake_offset
	target_position.y += headbutt_pose.x - _landing_kick
	target_position.z += headbutt_pose.y + _weapon_recoil_back

	var recoil_smoothing := 32.0 if _weapon_recoil_kick_time > 0.0 else camera_smoothing
	var smoothing := _exp_weight(recoil_smoothing, delta)
	camera.position = camera.position.lerp(target_position, smoothing)
	camera.rotation.x = lerp_angle(
		camera.rotation.x,
		(
			_look_pitch
			+ headbutt_pose.z
			+ _landing_kick * 0.65
			- _weapon_recoil_pitch
			+ shake_rotation.x
		),
		smoothing
	)
	camera.rotation.y = lerp_angle(
		camera.rotation.y,
		_weapon_recoil_yaw + shake_rotation.y,
		smoothing
	)
	camera.rotation.z = lerp_angle(
		camera.rotation.z,
		target_roll + _weapon_recoil_roll + shake_rotation.z,
		smoothing
	)

	var target_fov := _camera_start_fov
	if Input.is_physical_key_pressed(KEY_R):
		target_fov = aim_fov
	else:
		if Input.is_action_pressed("sprint") and _move_input.y < 0.0:
			target_fov += sprint_fov_boost * speed_ratio
		if _dash_time_left > 0.0:
			target_fov += dash_fov_boost
		if _has_active_web():
			var web_speed_ratio := clampf(
				(horizontal_speed - sprint_speed) / (web_max_speed - sprint_speed),
				0.0,
				1.0
			)
			target_fov += web_fov_boost * web_speed_ratio
		target_fov += _weapon_recoil_fov
	camera.fov = lerpf(camera.fov, target_fov, _exp_weight(8.0, delta))

	var recoil_recovery := _exp_weight(weapon_recoil_recovery, delta)
	_weapon_recoil_pitch = lerpf(_weapon_recoil_pitch, 0.0, recoil_recovery)
	_weapon_recoil_yaw = lerpf(_weapon_recoil_yaw, 0.0, recoil_recovery)
	_weapon_recoil_roll = lerpf(_weapon_recoil_roll, 0.0, recoil_recovery)
	_weapon_recoil_fov = lerpf(_weapon_recoil_fov, 0.0, _exp_weight(14.0, delta))
	_weapon_recoil_back = lerpf(_weapon_recoil_back, 0.0, _exp_weight(13.0, delta))
	_weapon_shake_strength = lerpf(
		_weapon_shake_strength,
		0.0,
		_exp_weight(18.0, delta)
	)


func _smoothstep(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _exp_weight(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)
