extends Node

var _glow_material: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	var body := owner as Node3D
	if body == null:
		body = get_parent() as Node3D
	if body == null:
		return
	_glow_material = StandardMaterial3D.new()
	_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_material.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
	_glow_material.emission_enabled = true
	_glow_material.emission = Color(1.0, 1.0, 1.0, 1.0)
	_glow_material.emission_energy_multiplier = 2.0
	for mesh: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(mesh)


func set_glow(enabled: bool) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.material_overlay = _glow_material if enabled else null
