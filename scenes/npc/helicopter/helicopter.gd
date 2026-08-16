extends CharacterBody3D


const SPEED = 50.0
const JUMP_VELOCITY = 4.5


@export var player: Node3D

#func _ready() -> void:
	#$MachineGun.start_shooting()

func _physics_process(delta: float) -> void:
	if player:
		print(player)
		_look_at_player()

		var target_pos = _get_target_pos()
		
		if $RayCast3D2.is_colliding():
			velocity.y = lerp(velocity.y, SPEED, 0.1)
		
		var dir = global_position.direction_to(target_pos)
		
		velocity = lerp(velocity, dir * SPEED, 0.1)

		if velocity:
			print(velocity)
			$MeshInstance3D.rotation.z = lerpf(0, deg_to_rad(10), velocity.x / SPEED)
			$MeshInstance3D.rotation.x = lerpf(0, deg_to_rad(10), velocity.z / SPEED)

		move_and_slide()


func _get_target_pos() -> Vector3:
	return (player.global_position + Vector3(0, 0, 20)) * -player.global_basis.z + Vector3(0, 10, 0)


func _look_at_player():
	var direction: Vector3 = self.global_position.direction_to(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	var target: Basis = Basis.looking_at(direction)

	# if in _process
	global_basis = global_basis.slerp(target, 0.01)

#func rotate_towards(object: Node3D, tgt: Node3D, delta: float, speed: float = 5.0):
	#if not is_instance_valid(tgt):
		#return
	#
	## Текущий и целевой кватернионы
	#var current_quat = object.transform.basis.get_rotation_quaternion()
	#var tgt_basis = Basis.looking_at(tgt.global_position - object.global_position, Vector3.UP)
	#var tgt_quat = tgt_basis.get_rotation_quaternion()
	#
	## Плавная сферическая интерполяция
	#var new_quat = current_quat.slerp(tgt_quat, clampf(speed * delta, 0.0, 1.0))
	#
	## Применяем обратно в трансформ, сохраняя позицию и масштаб
	#object.transform.basis = Basis(new_quat)


func _on_trigger_hellicopter_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body != self:
		player = body
