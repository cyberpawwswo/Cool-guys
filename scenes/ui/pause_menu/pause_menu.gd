extends Control

@onready var exit_the_menu := load("res://scenes/ui/main_menu/main_menu.tscn")

func _ready() -> void:
	# Разрешаем узлу работать, даже когда вся игра на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Прячем меню при старте уровня
	visible = false

func _input(event: InputEvent) -> void:
	# ui_cancel по умолчанию привязан к Esc
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	
	# Опционально: показываем/прячем курсор во время паузы
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed() -> void:
	toggle_pause() # Снимет паузу и спрячет меню

func _on_exit_the_menu_button_pressed() -> void:
	get_tree().paused = false # На всякий случай снимаем паузу перед сменой сцены
	get_tree().change_scene_to_packed(exit_the_menu)
