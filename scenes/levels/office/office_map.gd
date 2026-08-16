extends Node3D

const GLASS_TEXTURE := preload("res://assets/maps/office/Textures/glass4_c.jpg")
const DIRTY_GLASS_NORMAL := preload("res://assets/maps/office/Textures/glass_dirty_n.jpg")
const RED_INDICATOR_TEXTURE := preload("res://assets/maps/office/Textures/redblink_c.jpg")
const GREEN_INDICATOR_TEXTURE := preload("res://assets/maps/office/Textures/green_l_c.jpg")
const LIGHT_EMISSION_TEXTURE := preload("res://assets/maps/office/Textures/94_emiss.jpg")


func _ready() -> void:
	_repair_imported_materials()


func _repair_imported_materials() -> void:
	var repaired_materials: Dictionary = {}
	for node in $Model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		for surface_index in mesh_instance.mesh.get_surface_count():
			var imported := mesh_instance.get_active_material(surface_index) as StandardMaterial3D
			if imported == null:
				continue
			var key := imported.get_instance_id()
			if not repaired_materials.has(key):
				var repaired := imported.duplicate() as StandardMaterial3D
				_configure_material(repaired)
				repaired_materials[key] = repaired
			mesh_instance.set_surface_override_material(surface_index, repaired_materials[key])


func _configure_material(material: StandardMaterial3D) -> void:
	var material_name := material.resource_name.to_lower()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	if material_name == "glass_4":
		material.albedo_texture = GLASS_TEXTURE
	if material_name == "glass_dirty":
		material.normal_enabled = true
		material.normal_texture = DIRTY_GLASS_NORMAL
	if material_name == "redblink_m":
		material.albedo_texture = RED_INDICATOR_TEXTURE
	if material_name == "green_l_m":
		material.albedo_texture = GREEN_INDICATOR_TEXTURE

	if "glass" in material_name or "tranclucent" in material_name:
		_configure_glass(material, material_name)

	if _is_light_material(material_name):
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_texture = material.albedo_texture
		material.emission_energy_multiplier = 1.8

	if material_name == "94m":
		material.emission_enabled = true
		material.emission = Color.WHITE
		material.emission_texture = LIGHT_EMISSION_TEXTURE
		material.emission_energy_multiplier = 2.2


func _configure_glass(material: StandardMaterial3D, material_name: String) -> void:
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.32 if "dirty" in material_name else 0.08
	material.metallic_specular = 0.85
	material.albedo_color.a = 0.34 if "dirty" in material_name else 0.16


func _is_light_material(material_name: String) -> bool:
	return (
		"light" in material_name
		or material_name == "flicker_mat"
		or material_name == "rl_mat"
		or material_name == "redblink_m"
		or material_name == "green_l_m"
	)
