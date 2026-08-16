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
@export var web_rope_slack := 0.92
@export var web_min_rope_length := 3.5
@export var web_tension := 18.0
@export var web_spring_strength := 11.0
@export var web_steer_acceleration := 16.0
@export var web_forward_assist := 9.0
@export var web_attach_pull := 4.0
@export var web_release_boost := 5.5
@export var web_max_speed := 38.0
@export var web_air_drag := 0.035
@export var web_camera_roll_degrees := 5.0
@export var web_fov_boost := 9.0

@export_category("Camera")
@export var mouse_sensitivity := 0.005
@export var camera_smoothing := 14.0
@export var walk_bob_amount := 0.035
@export var sprint_bob_amount := 0.055
@export var bob_frequency := 2.1
@export var strafe_roll_degrees := 1.8
@export var turn_roll_degrees := 1.25
@export var sprint_fov_boost := 4.0
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

var _web_active := false
var _web_anchor := Vector3.ZERO
var _web_anchor_body: Node3D = null
var _web_anchor_local := Vector3.ZERO
var _web_rope_length := 0.0
var _web_hand_side := 1.0
var _web_line: MeshInstance3D
var _web_anchor_marker: MeshInstance3D
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
		rotate_y(-event.relative.x * mouse_sensitivity)
		_look_pitch = clampf(
			_look_pitch - event.relative.y * mouse_sensitivity,
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


func _update_blink(delta: float) -> void:
	if not _black_white_mode:
		return
	_blink_timer += delta
	if _blink_timer >= blink_interval:
		_blink_timer = 0.0
		_blink_alpha = blink_strength
	_blink_alpha = maxf(_blink_alpha - delta * blink_fade_speed, 0.0)
	blink_overlay.color.a = _blink_alpha


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

	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0 and not _web_active:
		_start_dash(move_direction)

	if _web_active:
		_update_web_swing(move_direction, delta)
	elif _dash_time_left > 0.0:
		var current_dash_speed := bw_dash_speed if _black_white_mode else dash_speed
		velocity.x = _dash_direction.x * current_dash_speed
		velocity.z = _dash_direction.z * current_dash_speed
	else:
		_update_horizontal_velocity(move_direction, delta)

	var vertical_speed_before_move := velocity.y
	move_and_slide()

	if not _was_on_floor and is_on_floor():
		_landing_kick = clampf(absf(vertical_speed_before_move) * 0.012, 0.0, 0.085)
	_was_on_floor = is_on_floor()
	_update_footstep_sounds(delta)
	_update_web_visual()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not _suppress_attack_this_frame:
		
		if weapon_manager.play_attack():
			_perform_attack()
	if Input.is_action_just_pressed("strong_attack"):
		if _headbutt_time < 0.0 and not _try_grab():
			_start_headbutt()
	if Input.is_action_just_released("strong_attack"):
		_release_throw()
	if Input.is_action_just_pressed("black_white"):
		_toggle_black_white_mode()
	_update_blink(delta)
	_update_shot_flash(delta)
	_suppress_attack_this_frame = false

	var headbutt_pose := _update_headbutt(delta)
	_update_camera(delta, headbutt_pose)


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
	web_material.albedo_color = Color(0.82, 0.95, 1.0, 1.0)
	web_material.emission_enabled = true
	web_material.emission = Color(0.28, 0.66, 1.0)
	web_material.emission_energy_multiplier = 1.8

	var line_mesh := CylinderMesh.new()
	line_mesh.top_radius = 0.028
	line_mesh.bottom_radius = 0.028
	line_mesh.height = 1.0
	line_mesh.radial_segments = 8
	line_mesh.material = web_material
	_web_line = MeshInstance3D.new()
	_web_line.name = "WebLine"
	_web_line.mesh = line_mesh
	_web_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_web_line.visible = false
	add_child(_web_line)
	_web_line.top_level = true

	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.11
	marker_mesh.height = 0.22
	marker_mesh.material = web_material
	_web_anchor_marker = MeshInstance3D.new()
	_web_anchor_marker.name = "WebAnchor"
	_web_anchor_marker.mesh = marker_mesh
	_web_anchor_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_web_anchor_marker.visible = false
	add_child(_web_anchor_marker)
	_web_anchor_marker.top_level = true

	_web_audio_player = AudioStreamPlayer.new()
	_web_audio_player.name = "WebShooterSound"
	_web_audio_player.stream = _create_web_sound()
	_web_audio_player.volume_db = -4.0
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
	if Input.is_action_just_pressed("web_swing"):
		var hit := _find_web_anchor()
		if not hit.is_empty():
			_attach_web(hit)
		else:
			crosshair.color = Color(1.0, 0.28, 0.22, 0.9)
	if not _web_active:
		crosshair.color = crosshair.color.lerp(
			Color(1.0, 1.0, 1.0, 0.6235),
			0.18
		)
		return
	if Input.is_action_just_pressed("jump"):
		_release_web(true)
	elif Input.is_action_just_released("web_swing"):
		_release_web(false)


func _find_web_anchor() -> Dictionary:
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var up := camera.global_transform.basis.y
	var right := camera.global_transform.basis.x
	var directions: Array[Vector3] = [
		forward,
		(forward + up * 0.2).normalized(),
		(forward + up * 0.38).normalized(),
		(forward - right * 0.24 + up * 0.22).normalized(),
		(forward + right * 0.24 + up * 0.22).normalized(),
		(forward - right * 0.42 + up * 0.3).normalized(),
		(forward + right * 0.42 + up * 0.3).normalized(),
		(forward - right * 0.72 + up * 0.26).normalized(),
		(forward + right * 0.72 + up * 0.26).normalized(),
	]
	var space_state := get_world_3d().direct_space_state
	var best_hit: Dictionary = {}
	var best_score := -INF
	for direction in directions:
		var query := PhysicsRayQueryParameters3D.create(
			origin,
			origin + direction * web_range
		)
		query.exclude = [get_rid()]
		query.collide_with_areas = false
		var hit := space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		if not hit.collider is StaticBody3D:
			continue
		var point: Vector3 = hit.position
		var height := point.y - global_position.y
		if height < web_min_anchor_height:
			continue
		var distance := origin.distance_to(point)
		var score := (
			height / web_range * 2.4
			+ direction.dot(forward) * 2.0
			- distance / web_range * 0.35
		)
		if score > best_score:
			best_score = score
			best_hit = hit
	return best_hit


func _attach_web(hit: Dictionary) -> void:
	_web_anchor = hit.position
	_web_anchor_body = hit.collider as Node3D
	if _web_anchor_body:
		_web_anchor_local = _web_anchor_body.to_local(_web_anchor)
	else:
		_web_anchor_local = Vector3.ZERO
	var distance := global_position.distance_to(_web_anchor)
	var desired_rope_length := distance * web_rope_slack
	if is_on_floor():
		var anchor_height := maxf(
			_web_anchor.y - global_position.y,
			web_min_rope_length
		)
		desired_rope_length = minf(
			desired_rope_length,
			anchor_height * 1.25
		)
	_web_rope_length = maxf(desired_rope_length, web_min_rope_length)
	_web_hand_side *= -1.0
	_web_active = true
	_dash_time_left = 0.0
	var pull_direction := (_web_anchor - global_position).normalized()
	velocity += pull_direction * web_attach_pull
	if is_on_floor():
		velocity.y = maxf(velocity.y, jump_velocity * 0.85)
	crosshair.color = Color(0.38, 0.9, 1.0, 1.0)
	_web_line.visible = true
	_web_anchor_marker.visible = true
	if _web_audio_player:
		_web_audio_player.pitch_scale = randf_range(0.96, 1.06)
		_web_audio_player.play()


func _release_web(boosted: bool) -> void:
	if not _web_active:
		return
	_web_active = false
	_web_anchor_body = null
	_web_line.visible = false
	_web_anchor_marker.visible = false
	crosshair.color = Color(1.0, 1.0, 1.0, 0.6235)
	if boosted:
		var forward := -camera.global_transform.basis.z
		var launch_direction := (forward + Vector3.UP * 0.48).normalized()
		velocity += launch_direction * web_release_boost
		if velocity.length() > web_max_speed:
			velocity = velocity.normalized() * web_max_speed
		if _web_audio_player:
			_web_audio_player.pitch_scale = 1.32
			_web_audio_player.play()


func _refresh_web_anchor() -> bool:
	if _web_anchor_body == null:
		return true
	if not is_instance_valid(_web_anchor_body):
		_release_web(false)
		return false
	_web_anchor = _web_anchor_body.to_global(_web_anchor_local)
	return true


func _update_web_swing(move_direction: Vector3, delta: float) -> void:
	if not _refresh_web_anchor():
		return
	var to_anchor := _web_anchor - global_position
	var distance := to_anchor.length()
	if distance < 0.01 or distance > web_range * 1.35:
		_release_web(false)
		return
	var radial_direction := to_anchor / distance
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

	if _move_input.y < -0.05:
		var forward_tangent := (-camera.global_transform.basis.z).slide(radial_direction)
		if forward_tangent.length_squared() > 0.001:
			velocity += forward_tangent.normalized() * web_forward_assist * delta

	if distance > _web_rope_length:
		var stretch := distance - _web_rope_length
		var away_speed := velocity.dot(-radial_direction)
		if away_speed > 0.0:
			velocity += radial_direction * away_speed
		velocity += radial_direction * (
			web_tension + stretch * web_spring_strength
		) * delta

	velocity *= maxf(1.0 - web_air_drag * delta, 0.0)
	if velocity.length() > web_max_speed:
		velocity = velocity.normalized() * web_max_speed


func _update_web_visual() -> void:
	if not _web_active or not _refresh_web_anchor():
		return
	var line_start := camera.global_position + (
		camera.global_transform.basis * Vector3(
			0.28 * _web_hand_side,
			-0.2,
			-0.42
		)
	)
	var line_vector := _web_anchor - line_start
	var line_length := line_vector.length()
	if line_length < 0.01:
		return
	var line_mesh := _web_line.mesh as CylinderMesh
	line_mesh.height = line_length
	_web_line.global_transform = Transform3D(
		Basis(Quaternion(Vector3.UP, line_vector / line_length)),
		line_start + line_vector * 0.5
	)
	_web_anchor_marker.global_position = _web_anchor


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
	if _web_active:
		var local_anchor_direction := camera.global_transform.basis.inverse() * (
			_web_anchor - camera.global_position
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
	if Input.is_action_pressed("sprint") and _move_input.y < 0.0:
		target_fov += sprint_fov_boost * speed_ratio
	if _dash_time_left > 0.0:
		target_fov += dash_fov_boost
	if _web_active:
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
