extends Node

var _glow_material: StandardMaterial3D

func _ready() -> void:
	_glow_material = StandardMaterial3D.new()
	_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_material.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
	_glow_material.emission_enabled = true
	_glow_material.emission = Color(1.0, 1.0, 1.0, 1.0)
	_glow_material.emission_energy_multiplier = 2.0

func set_glow(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("glow_body"):
		if not is_instance_valid(node):
			continue
		for mesh: MeshInstance3D in _collect_meshes(node):
			mesh.material_overlay = _glow_material if enabled else null

func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		meshes.append_array(_collect_meshes(child))
	return meshes
