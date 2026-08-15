extends CharacterBody3D


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
@export var headbutt_windup_tilt_degrees := 42.0
@export var headbutt_tilt_degrees := 18.0

@export_category("Black & White")
@export var blink_interval := 1.0
@export var blink_strength := 0.45
@export var blink_fade_speed := 3.5

@onready var camera: Camera3D = $Camera3D
@onready var ray: RayCast3D = $Camera3D/RayCast3D
@onready var weapon_manager = $Control/ViewmodelContainer/ViewmodelViewport/ViewmodelCamera/WeaponManager
@onready var gray_filter: ColorRect = $Effects/GrayFilter
@onready var blink_overlay: ColorRect = $Effects/BlinkOverlay
@onready var shot_flash: ColorRect = $Effects/ShotFlash
@onready var pause_menu: Control = $PauseMenus/PauseMenu
@onready var pause_menu_bw: Control = $PauseMenus/PauseMenuBW

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
var _weapon_shake_time := 0.0
var _weapon_shake_strength := 0.0
var _weapon_shake_phase := 0.0
var _shot_flash_alpha := 0.0

var _dash_time_left := 0.0
var _dash_cooldown_left := 0.0
var _dash_direction := Vector3.ZERO
var _coyote_time_left := 0.0
var _jump_buffer_left := 0.0

var _headbutt_time := -1.0
var _headbutt_cooldown_left := 0.0
var _headbutt_has_hit := false
var _suppress_attack_this_frame := false

var _black_white_mode := false
var _blink_timer := 0.0
var _blink_alpha := 0.0


func _ready() -> void:
	_camera_start_position = camera.position
	_camera_start_fov = camera.fov
	_look_pitch = camera.rotation.x
	_was_on_floor = is_on_floor()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gray_filter.visible = false
	blink_overlay.color.a = 0.0
	shot_flash.color.a = 0.0
	pause_menu_bw.visible = false


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

	_move_input = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var move_direction := (
		transform.basis * Vector3(_move_input.x, 0.0, _move_input.y)
	).normalized()

	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0:
		_start_dash(move_direction)

	if _dash_time_left > 0.0:
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
	else:
		_update_horizontal_velocity(move_direction, delta)

	var vertical_speed_before_move := velocity.y
	move_and_slide()

	if not _was_on_floor and is_on_floor():
		_landing_kick = clampf(absf(vertical_speed_before_move) * 0.012, 0.0, 0.085)
	_was_on_floor = is_on_floor()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not _suppress_attack_this_frame:
		
		if weapon_manager.play_attack():
			_perform_attack()
	if Input.is_action_just_pressed("strong_attack"):
		_start_headbutt()
	if Input.is_action_just_pressed("black_white"):
		_toggle_black_white_mode()
	_update_blink(delta)
	_update_shot_flash(delta)
	_suppress_attack_this_frame = false

	var headbutt_pose := _update_headbutt(delta)
	_update_camera(delta, headbutt_pose)


func apply_weapon_recoil(strength: float) -> void:
	_weapon_recoil_pitch = minf(
		_weapon_recoil_pitch + deg_to_rad(4.5) * strength,
		deg_to_rad(8.0)
	)
	_weapon_recoil_yaw += deg_to_rad(randf_range(-1.2, 1.2)) * strength
	_weapon_recoil_roll += deg_to_rad(randf_range(-1.4, 1.4)) * strength
	_weapon_recoil_fov = maxf(_weapon_recoil_fov, 2.4 * strength)
	_weapon_shake_time = maxf(_weapon_shake_time, 0.12 + 0.08 * strength)
	_weapon_shake_strength = maxf(_weapon_shake_strength, 0.035 * strength)
	_shot_flash_alpha = maxf(_shot_flash_alpha, 0.38 * strength)


func _update_shot_flash(delta: float) -> void:
	_shot_flash_alpha = maxf(_shot_flash_alpha - delta * 2.8, 0.0)
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


func _start_dash(move_direction: Vector3) -> void:
	_dash_direction = move_direction
	if _dash_direction == Vector3.ZERO:
		_dash_direction = -transform.basis.z

	_dash_direction.y = 0.0
	_dash_direction = _dash_direction.normalized()
	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown


func _update_horizontal_velocity(move_direction: Vector3, delta: float) -> void:
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
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


func _update_headbutt(delta: float) -> Vector3:
	if _headbutt_time < 0.0:
		return Vector3.ZERO

	_headbutt_time += delta
	var progress := clampf(_headbutt_time / headbutt_duration, 0.0, 1.0)

	if not _headbutt_has_hit and progress >= 0.52:
		_perform_attack(true)
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

	return Vector3(height_offset, forward_offset, pitch_offset)


func _perform_attack(close_only := false) -> void:
	if not ray.is_colliding():
		return

	var body := ray.get_collider()
	if body == null:
		return

	var hit_point := ray.get_collision_point()
	var distance_to_hit := global_position.distance_to(hit_point)
	if close_only and distance_to_hit > close_distance:
		return
	var attack_power := impulse
	if distance_to_hit <= close_distance:
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
	_weapon_shake_phase += delta * 72.0
	var shake_ratio := clampf(_weapon_shake_time / 0.2, 0.0, 1.0)
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
	var target_position := _camera_start_position + bob_offset + shake_offset
	target_position.y += headbutt_pose.x - _landing_kick
	target_position.z += headbutt_pose.y

	var smoothing := _exp_weight(camera_smoothing, delta)
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
	target_fov += _weapon_recoil_fov
	camera.fov = lerpf(camera.fov, target_fov, _exp_weight(8.0, delta))

	var recoil_recovery := _exp_weight(weapon_recoil_recovery, delta)
	_weapon_recoil_pitch = lerpf(_weapon_recoil_pitch, 0.0, recoil_recovery)
	_weapon_recoil_yaw = lerpf(_weapon_recoil_yaw, 0.0, recoil_recovery)
	_weapon_recoil_roll = lerpf(_weapon_recoil_roll, 0.0, recoil_recovery)
	_weapon_recoil_fov = lerpf(_weapon_recoil_fov, 0.0, _exp_weight(14.0, delta))
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
