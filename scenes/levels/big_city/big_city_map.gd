extends Node3D

const MERGED_CONCRETE := preload("res://assets/maps/big_city/merged_concrete.png")


func _ready() -> void:
	_configure_materials($Model)


func _configure_materials(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for surface_index in node.mesh.get_surface_count():
			var material := node.get_active_material(surface_index) as StandardMaterial3D
			if material == null:
				continue
			var configured := material.duplicate() as StandardMaterial3D
			configured.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			configured.roughness = maxf(configured.roughness, 0.68)
			if configured.resource_name == "Merged_materials":
				configured.albedo_texture = MERGED_CONCRETE
				configured.albedo_color = Color(0.58, 0.6, 0.62)
				configured.uv1_triplanar = true
				configured.uv1_world_triplanar = true
				configured.uv1_scale = Vector3(0.12, 0.12, 0.12)
			node.set_surface_override_material(surface_index, configured)
	for child in node.get_children():
		_configure_materials(child)
