extends Node

@export var floor_material: StandardMaterial3D
@export var wall_material: StandardMaterial3D
@export var inner_material: StandardMaterial3D
@export var sun: DirectionalLight3D
@export var environment: Environment
@export var bw_cutoff_hz := 700.0

var _defaults: Dictionary = {}
var _muffle_filter: AudioEffectFilter = null

func _ready() -> void:
	if floor_material:
		_defaults["floor"] = floor_material.albedo_color
		_defaults["floor_specular"] = floor_material.metallic_specular
	if wall_material:
		_defaults["wall"] = wall_material.albedo_color
		_defaults["wall_specular"] = wall_material.metallic_specular
	if inner_material:
		_defaults["inner"] = inner_material.albedo_color
		_defaults["inner_specular"] = inner_material.metallic_specular
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
	_setup_muffle_filter()


func _setup_muffle_filter() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return
	for i in AudioServer.get_bus_effect_count(master):
		var effect := AudioServer.get_bus_effect(master, i)
		if effect is AudioEffectFilter and effect.resource_name == "BWMuffle":
			_muffle_filter = effect
			AudioServer.remove_bus_effect(master, i)
			return
	_muffle_filter = AudioEffectFilter.new()
	_muffle_filter.resource_name = "BWMuffle"
	_muffle_filter.cutoff_hz = bw_cutoff_hz


func _apply_muffle(active: bool) -> void:
	if _muffle_filter == null:
		return
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) == _muffle_filter:
			if not active:
				AudioServer.remove_bus_effect(master, i)
			return
	if active:
		AudioServer.add_bus_effect(master, _muffle_filter)


func set_dark_mode(dark: bool) -> void:
	_apply_muffle(dark)
	if floor_material:
		floor_material.albedo_color = Color(0.03, 0.03, 0.03, 1) if dark else _defaults.get("floor", Color.WHITE)
		floor_material.metallic_specular = 0.0 if dark else _defaults.get("floor_specular", 0.5)
	if wall_material:
		wall_material.albedo_color = Color(0.03, 0.03, 0.03, 1) if dark else _defaults.get("wall", Color.WHITE)
		wall_material.metallic_specular = 0.0 if dark else _defaults.get("wall_specular", 0.5)
	if inner_material:
		inner_material.albedo_color = Color(0.02, 0.02, 0.02, 1) if dark else _defaults.get("inner", Color.WHITE)
		inner_material.metallic_specular = 0.0 if dark else _defaults.get("inner_specular", 0.5)
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
	GlowManager.set_glow(dark)
