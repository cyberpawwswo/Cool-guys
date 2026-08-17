extends Node3D

## Тун Саhур: летает вокруг игрока высоко в небе, периодически замирает
## и фигачит мощнейшим лазером из глаз.

@export_group("Flight")
@export var orbit_radius := 28.0
@export var fly_height := 35.0
@export var orbit_speed := 0.2

@export_group("Attack")
@export var attack_interval_min := 5.0
@export var attack_interval_max := 9.0
@export var charge_time := 0.9
@export var laser_time := 1.6
@export var laser_dps := 30.0
@export var laser_range := 90.0
@export var sprite_height := 22.0

const POSE_FLY := "res://assets/tuan_sahur/pose1.png"
const POSE_ATTACK := "res://assets/tuan_sahur/pose2.png"

@onready var sprite: Sprite3D = $Sprite3D
@onready var eye_light: OmniLight3D = $EyeLight

var _player: Node3D
var _state := "fly"
var _orbit_angle := 0.0
var _attack_timer := 8.0
var _phase_timer := 0.0
var _pose_fly: Texture2D
var _pose_attack: Texture2D

var _laser_root: Node3D
var _laser_core: MeshInstance3D
var _laser_glow: MeshInstance3D
var _impact_light: OmniLight3D
var _impact_orb: MeshInstance3D


func _ready() -> void:
	_attack_timer = randf_range(attack_interval_min, attack_interval_max)
	eye_light.visible = false
	_build_laser()
	_load_poses()


func _process(delta: float) -> void:
	_find_player()
	if _player == null:
		return
	match _state:
		"fly":
			_orbit_angle += delta * orbit_speed
			var target := _player.global_position + Vector3(
				cos(_orbit_angle) * orbit_radius,
				fly_height,
				sin(_orbit_angle) * orbit_radius
			)
			global_position = global_position.lerp(target, delta * 2.0)
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_start_charge()
		"charge":
			_face_player()
			_phase_timer -= delta
			var charge_progress := clampf(1.0 - _phase_timer / charge_time, 0.0, 1.0)
			eye_light.visible = true
			eye_light.light_energy = 2.0 + charge_progress * 10.0
			if _phase_timer <= 0.0:
				_start_laser()
		"laser":
			_face_player()
			_phase_timer -= delta
			_update_laser()
			if _player.global_position.distance_to(global_position) <= laser_range:
				_player.take_damage(laser_dps * delta)
			if _phase_timer <= 0.0:
				_finish_attack()


func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().current_scene.find_child("Player", true, false)


func _face_player() -> void:
	var to_player := _player.global_position - global_position
	if to_player.length_squared() > 0.0001:
		look_at(_player.global_position, Vector3.UP)


func _start_charge() -> void:
	_state = "charge"
	_phase_timer = charge_time
	sprite.texture = _pose_attack
	_laser_root.visible = false


func _start_laser() -> void:
	_state = "laser"
	_phase_timer = laser_time
	_laser_root.visible = true
	eye_light.light_energy = 14.0
	_update_laser()


func _finish_attack() -> void:
	_state = "fly"
	_laser_root.visible = false
	eye_light.visible = false
	sprite.texture = _pose_fly
	_attack_timer = randf_range(attack_interval_min, attack_interval_max)


func _update_laser() -> void:
	var from := global_position + Vector3.UP * sprite_height * 0.12
	var to := _player.global_position + Vector3.UP
	var beam_length := from.distance_to(to)
	if beam_length < 0.01:
		return
	_laser_root.global_position = from
	_laser_root.look_at(to, Vector3.UP)
	var back := Vector3(0.0, 0.0, -beam_length * 0.5)
	_laser_core.position = back
	_laser_core.scale = Vector3(1.0, 1.0, beam_length)
	_laser_glow.position = back
	_laser_glow.scale = Vector3(1.0, 1.0, beam_length)
	_impact_light.position = Vector3(0.0, 0.0, -beam_length)
	_impact_light.light_energy = 9.0 + 3.0 * sin(Time.get_ticks_msec() * 0.05)
	_impact_orb.position = Vector3(0.0, 0.0, -beam_length)
	var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.04)
	_impact_orb.scale = Vector3.ONE * pulse


func _build_laser() -> void:
	_laser_root = Node3D.new()
	_laser_root.name = "LaserBeam"
	add_child(_laser_root)

	_laser_glow = MeshInstance3D.new()
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(0.85, 0.85, 1.0)
	glow_mesh.material = _beam_material(Color(1.0, 0.08, 0.0), 0.9, 5.0)
	_laser_glow.mesh = glow_mesh
	_laser_root.add_child(_laser_glow)

	_laser_core = MeshInstance3D.new()
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.16, 0.16, 1.0)
	core_mesh.material = _beam_material(Color(1.0, 0.5, 0.3), 2.2, 42.0)
	_laser_core.mesh = core_mesh
	_laser_root.add_child(_laser_core)

	_impact_light = OmniLight3D.new()
	_impact_light.light_color = Color(1.0, 0.12, 0.05)
	_impact_light.omni_range = 16.0
	_impact_light.light_energy = 0.0
	_laser_root.add_child(_impact_light)

	_impact_orb = MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.8
	orb_mesh.height = 1.6
	var orb_mat := StandardMaterial3D.new()
	orb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orb_mat.albedo_color = Color(1.0, 0.2, 0.1, 0.9)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(1.0, 0.15, 0.05)
	orb_mat.emission_energy_multiplier = 6.0
	orb_mesh.material = orb_mat
	_impact_orb.mesh = orb_mesh
	_laser_root.add_child(_impact_orb)


func _beam_material(beam_color: Color, intensity: float, falloff: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 beam_color : source_color;
uniform float intensity : hint_range(0.0, 5.0) = 1.0;
uniform float falloff : hint_range(0.0, 80.0) = 10.0;

void fragment() {
	vec2 c = VERTEX.xy;
	float r = length(c);
	float glow = exp(-r * r * falloff);
	float pulse = 0.85 + 0.2 * sin(TIME * 55.0) + 0.1 * sin(TIME * 91.0);
	ALBEDO = beam_color.rgb;
	EMISSION = beam_color.rgb * glow * intensity * pulse * 7.0;
	ALPHA = glow * clamp(intensity, 0.0, 1.4) * pulse;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("beam_color", beam_color)
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("falloff", falloff)
	return material


func _load_poses() -> void:
	_pose_fly = load(POSE_FLY)
	_pose_attack = load(POSE_ATTACK)
	var texture: Texture2D = _pose_fly if _pose_fly else _pose_attack
	if texture:
		sprite.texture = texture
		sprite.pixel_size = sprite_height / float(texture.get_height())
