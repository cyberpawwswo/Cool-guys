extends Node

@export var floor_material: StandardMaterial3D
@export var wall_material: StandardMaterial3D
@export var inner_material: StandardMaterial3D
@export var sun: DirectionalLight3D
@export var environment: Environment

var _defaults: Dictionary = {}

func _ready() -> void:
	if floor_material:
		_defaults["floor"] = floor_material.albedo_color
	if wall_material:
		_defaults["wall"] = wall_material.albedo_color
	if inner_material:
		_defaults["inner"] = inner_material.albedo_color
	if sun:
		_defaults["light"] = sun.light_energy
	if environment:
		_defaults["ambient_source"] = environment.ambient_light_source
		_defaults["ambient_energy"] = environment.ambient_light_energy
		_defaults["ambient_color"] = environment.ambient_light_color
		var sky: Sky = environment.sky
		if sky:
			var sky_mat := sky.sky_material as ProceduralSkyMaterial
			if sky_mat:
				_defaults["sky_top"] = sky_mat.sky_top_color
				_defaults["sky_horizon"] = sky_mat.sky_horizon_color
				_defaults["ground_horizon"] = sky_mat.ground_horizon_color
				_defaults["ground_bottom"] = sky_mat.ground_bottom_color


func set_dark_mode(dark: bool) -> void:
	if floor_material:
		floor_material.albedo_color = Color(0.03, 0.03, 0.03, 1) if dark else _defaults.get("floor", Color.WHITE)
	if wall_material:
		wall_material.albedo_color = Color(0.03, 0.03, 0.03, 1) if dark else _defaults.get("wall", Color.WHITE)
	if inner_material:
		inner_material.albedo_color = Color(0.02, 0.02, 0.02, 1) if dark else _defaults.get("inner", Color.WHITE)
	if sun:
		sun.light_energy = 0.45 if dark else _defaults.get("light", 1.0)
	if environment:
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if dark else _defaults.get("ambient_source", Environment.AMBIENT_SOURCE_BG)
		environment.ambient_light_energy = 0.3 if dark else _defaults.get("ambient_energy", 1.0)
		environment.ambient_light_color = Color(0.08, 0.08, 0.1, 1) if dark else _defaults.get("ambient_color", Color.WHITE)
		var sky: Sky = environment.sky
		if sky:
			var sky_mat := sky.sky_material as ProceduralSkyMaterial
			if sky_mat:
				sky_mat.sky_top_color = Color(0.02, 0.02, 0.03, 1) if dark else _defaults.get("sky_top", Color(0.4, 0.45, 0.55, 1))
				sky_mat.sky_horizon_color = Color(0.04, 0.04, 0.05, 1) if dark else _defaults.get("sky_horizon", Color(0.66, 0.67, 0.69, 1))
				sky_mat.ground_horizon_color = Color(0.03, 0.03, 0.03, 1) if dark else _defaults.get("ground_horizon", Color(0.66, 0.67, 0.69, 1))
				sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.01, 1) if dark else _defaults.get("ground_bottom", Color(0.2, 0.17, 0.13, 1))
	for glow: Node in get_tree().get_nodes_in_group("glow_body"):
		if glow.has_method("set_glow"):
			glow.set_glow(dark)
