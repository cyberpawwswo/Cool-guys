extends Node3D

@export var rate_of_fire := 10.0
@export var number_of_rounds := 400
@export var damage := 0

@export var shoot_ray_cast: RayCast3D

@export var explution_effter_shoot: ExplusionComplation
@export var explution_shoot: ExplusionComplation

@export var max_angle := deg_to_rad(30) 

var timer_shoot: Timer



var target: Node3D:
	set(new_value):
		target = new_value


func _ready() -> void:
	timer_shoot = Timer.new()
	add_child(timer_shoot)
	timer_shoot.timeout.connect(shoot)



@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if target:
		#var angle = (-shoot_ray_cast.global_basis.z).angle_to(shoot_ray_cast.target_position)
		#if angle < max_angle:
		rotate_towards(shoot_ray_cast, target, delta, 2.0)
	else:
		var a = Quaternion(shoot_ray_cast.global_basis)
		var b = Quaternion(global_basis)
		var c = a.slerp(b,0.5)
		shoot_ray_cast.global_basis = Basis(c)

func rotate_towards(object: Node3D, tgt: Node3D, delta: float, speed: float = 5.0):
	if not is_instance_valid(tgt):
		return
	
	# Текущий и целевой кватернионы
	var current_quat = object.global_basis.get_rotation_quaternion()
	var tgt_basis = Basis.looking_at(tgt.global_position - object.global_position, Vector3.UP)
	var tgt_quat = tgt_basis.get_rotation_quaternion()
	
	# Плавная сферическая интерполяция
	var new_quat = current_quat.slerp(tgt_quat, clampf(speed * delta, 0.0, 1.0))
	
	# Применяем обратно в трансформ, сохраняя позицию и масштаб
	object.global_basis = Basis(new_quat)

func start_shooting():
	timer_shoot.wait_time = rate_of_fire
	timer_shoot.start()

func shoot():
	if explution_shoot:
		explution_shoot.emitting()
		print('123')
	print(explution_shoot)
	if shoot_ray_cast:
		if shoot_ray_cast.is_colliding():
			var collider = shoot_ray_cast.get_collider()

			var tween = create_tween()
			tween.tween_interval(0.1)
			tween.tween_callback(spawn_explosion_quat.bind(shoot_ray_cast.get_collision_normal(), shoot_ray_cast.get_collision_point(), collider))

func spawn_explosion_quat(normal: Vector3, pos: Vector3, collider):
	var quat = Quaternion(Vector3.BACK, normal.normalized())

	var explosion_transform = Transform3D(Basis(quat), pos)
	
	if "hp" in collider:
		collider.hp -= damage

	if explution_effter_shoot:
		var expl = explution_effter_shoot.duplicate()
		get_parent().get_parent().add_child(expl)
		expl.emitting()
		expl.global_transform = explosion_transform


func end_shooting():
	timer_shoot.stop()
