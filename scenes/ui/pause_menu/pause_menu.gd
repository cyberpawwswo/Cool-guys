extends Control

@onready var exit_the_menu := load("res://scenes/ui/main_menu/main_menu.tscn")

func _ready() -> void:
	# Разрешаем узлу работать, даже когда вся игра на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Прячем меню при старте уровня
	visible = false

	var buttons := $CenterContainer/VBoxContainer.get_children().filter(func(c): return c is Button)
	for button in buttons:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.resized.connect(_update_pivot.bind(button))
		_update_pivot(button)

func _input(event: InputEvent) -> void:
	# ui_cancel по умолчанию привязан к Esc
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused

	if is_paused:
		var menu_box := $CenterContainer/VBoxContainer
		menu_box.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(menu_box, "modulate:a", 1.0, 0.25)
		$CenterContainer/VBoxContainer/ResumeButton.grab_focus()

	# Опционально: показываем/прячем курсор во время паузы
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func _update_pivot(node: Control) -> void:
	node.pivot_offset = node.size / 2.0

func _on_button_hovered(button: Button) -> void:
	var tween := create_tween()
	var anim := tween.tween_property(button, "scale", Vector2(1.06, 1.06), 0.12)
	anim.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_button_unhovered(button: Button) -> void:
	var tween := create_tween()
	var anim := tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	anim.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_resume_button_pressed() -> void:
	toggle_pause() # Снимет паузу и спрячет меню

func _on_exit_the_menu_button_pressed() -> void:
	get_tree().paused = false # На всякий случай снимаем паузу перед сменой сцены
	get_tree().change_scene_to_packed(exit_the_menu)
