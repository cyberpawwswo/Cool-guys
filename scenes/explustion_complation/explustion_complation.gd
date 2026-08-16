extends Node3D
class_name ExplusionComplation

func emitting():
	for i in get_children():
		(i as GPUParticles3D).emitting = true
