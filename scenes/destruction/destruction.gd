extends Node
class_name Destruction

var path_destructions_folder := "res://assets/destruction/"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_forward"):
		print("asfsf")
		destruction()

func destruction():
	for i in get_parent().get_children():
		if i is MeshInstance3D:
			var obj = load(str(path_destructions_folder + i.mesh.resource_path + "_destruction.tscn"))
