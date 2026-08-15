@tool
extends Node
class_name DestroyedController

const SAVE_DESTRACTION_FOLDER := "res://resource/destoy/scenes/"

@export var meshe: MeshInstance3D

@export_tool_button("Generate Fracture meshe") var excute_action = _execute_update 


var destroy_server: VoronoiShatter

@export var seed_saved: int
@export var setting := DestroySettings.new() 
@export var life_time := 20.0


func _execute_update():
	for i in get_children():
		i.free()

	destroy_server = VoronoiShatter.new()
	add_child(destroy_server)
	_parse_settings_to_shatter(setting, destroy_server)

	if setting.use_mesh_materials:
		destroy_server.outer_material = meshe.get_surface_override_material(0)

	destroy_server.add_child(meshe.duplicate())

	print(destroy_server.get_children(), ' 1244')

	await destroy_server.execute()
	
	var timer = Timer.new()
	add_child(timer)
	timer.start()
	timer.one_shot = true

	await timer.timeout

	for i in destroy_server.get_children():
		if is_instance_of(i, VoronoiCollection):
			print('start')
			await i.create_rigid_bodies()
			print('end')
		else:
			i.queue_free()

	timer.start()
	await timer.timeout
	_save_self_to_resourse()



func _set_ownership(p_owner, node):
	for c in node.get_children():
		c.owner = p_owner
		_set_ownership(p_owner, c)



func _save_self_to_resourse():
	_set_ownership(destroy_server, destroy_server)
	
	var packed_self = PackedScene.new()
	packed_self.pack(destroy_server)

	var err = ResourceSaver.save(packed_self, _get_path_save_destroy())
	print(err)

	for i in get_children():
		i.queue_free()



func _get_path_save_destroy():
	print(seed_saved)
	return SAVE_DESTRACTION_FOLDER + self.name + "_" + str(seed_saved) + "_destroyed.tscn"



## Парсит настройки из GenerationSettings и применяет их к VoronoiShatter.
## Игнорирует use_mesh_materials.
func _parse_settings_to_shatter(settings: DestroySettings, shatter: VoronoiShatter) -> void:
	if not settings or not shatter:
		push_error("parse_settings_to_shatter: settings или shatter невалидны")
		return
	
	# Materials
	shatter.random_color = settings.random_color
	shatter.inherit_outer_material = settings.inherit_outer_material
	shatter.outer_material = settings.outer_material
	shatter.inner_material = settings.inner_material
	
	# Structure
	shatter.samples = settings.samples
	shatter.seed = settings.seed
	shatter.cell_scale = settings.cell_scale
	shatter.sample_texture = settings.sample_texture
	
	# Randomize seed (если галочка установлена - генерируем новый сид)
	if settings.randomize_seed:
		shatter.randomize_seed()




func destroy():
	var spawn_mesh_transform: Transform3D
	if is_instance_valid(meshe):
		spawn_mesh_transform = meshe.global_transform
		meshe.queue_free()
	
	var destroy_resource = (load(_get_path_save_destroy()) as PackedScene).instantiate()
	add_child(destroy_resource)
	destroy_resource.global_transform = spawn_mesh_transform

	var tween = create_tween()
	tween.tween_interval(life_time)
	tween.tween_callback(destroy_resource.queue_free)
