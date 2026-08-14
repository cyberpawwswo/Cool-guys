extends CharacterBody3D

const WALK_SPEED = 5.0
const SPRINT_SPEED = 9.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.005

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if camera == null:
		push_error("❌ Камера не найдена! Проверь имя в дереве сцены.")

func _unhandled_input(event: InputEvent) -> void:
	# Выход из захвата мыши по Escape
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion and camera:
		# Поворот персонажа по горизонтали
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Поворот камеры по вертикали
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		# Ограничение угла обзора
		camera.rotation.x = clamp(camera.rotation.x, -PI/2.2, PI/2.2)

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Направление движения
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Спринт
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
