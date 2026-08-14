extends CharacterBody3D

@onready var ray: RayCast3D = $Camera3D/RayCast3D


@export var CLOSE_DISTANCE: float = 2.0
@export var CLOSE_MULTIPLIER: float = 3.0

@export var headbutt = 20

@export var IMPULSE: float = 20.0

var camera_recoil: float = 0.0

@onready var camera_start_pos: Vector3 = $Camera3D.position


const WALK_SPEED = 5.0
const SPRINT_SPEED = 9.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.005

# Настройки рывка
const DASH_SPEED = 18.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.8

var dash_time_left := 0.0
var dash_cooldown_left := 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if camera == null:
		push_error("❌ Камера не найдена! Проверь имя в дереве сцены.")

func _input(event: InputEvent) -> void:
	# Выход из захвата мыши по Escape
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion and camera:
		# Поворот персонажа по горизонтали
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Поворот камеры по вертикали
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		# Ограничение угла обзора
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2.2, PI / 2.2)

func _physics_process(delta: float) -> void:
	# Перезарядка рывка
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	
	if dash_time_left > 0.0:
		dash_time_left -= delta
	
	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Направление движения
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	# Рывок
	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
		var dash_direction := direction
		
		# Если игрок не движется — рывок вперёд
		if dash_direction == Vector3.ZERO:
			dash_direction = -transform.basis.z
		
		# Рывок только по горизонтали
		dash_direction.y = 0.0
		dash_direction = dash_direction.normalized()
		
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
		
		dash_time_left = DASH_DURATION
		dash_cooldown_left = DASH_COOLDOWN

	# Пока идёт рывок — поддерживаем скорость рывка
	if dash_time_left > 0.0:
		var dash_dir := direction
		
		if dash_dir == Vector3.ZERO:
			dash_dir = Vector3(velocity.x, 0.0, velocity.z).normalized()
		
		if dash_dir != Vector3.ZERO:
			velocity.x = dash_dir.x * DASH_SPEED
			velocity.z = dash_dir.z * DASH_SPEED
	else:
		# Обычное движение
		var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		
		if direction != Vector3.ZERO:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

func _process(delta: float) -> void:
	if $Camera3D/RayCast3D.is_colliding():
		var body = $Camera3D/RayCast3D.get_collider()

		if body != null and Input.is_action_just_pressed("attack"):
			var hit_point: Vector3 = $Camera3D/RayCast3D.get_collision_point()
			var dist: float = global_position.distance_to(hit_point)
			var is_close: bool = dist <= CLOSE_DISTANCE

			var power: float = IMPULSE
			if is_close:
				power *= CLOSE_MULTIPLIER

			var dir: Vector3 = hit_point - global_position
			if dir.length_squared() < 0.001:
				dir = -$Camera3D.global_transform.basis.z

			dir = dir.normalized()

			var rb := body as RigidBody3D
			if rb:
				rb.apply_central_impulse(dir * power)

			if "hp" in body:
				body.hp = 0

			

#func headbutt() -> void:
	
