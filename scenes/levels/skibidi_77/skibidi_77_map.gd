extends Node3D

const BUILDING_FALLBACK_TEXTURE := preload("res://assets/maps/skibidi_77/textures/ROOF_CONCRETE.005_baseColor.png")


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
			configured.roughness = maxf(configured.roughness, 0.72)
			if "c_3dsky_globalpattern" in configured.resource_name.to_lower():
				configured.albedo_texture = BUILDING_FALLBACK_TEXTURE
				configured.albedo_color = Color.WHITE
			if configured.albedo_texture == null and configured.albedo_color.get_luminance() < 0.08:
				configured.albedo_color = Color(0.14, 0.15, 0.16, configured.albedo_color.a)
			node.set_surface_override_material(surface_index, configured)
	for child in node.get_children():
		_configure_materials(child)
