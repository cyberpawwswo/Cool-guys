extends Control

@onready var exit_the_menu := load("res://scenes/ui/main_menu/main_menu.tscn")
@onready var title: Label = $CenterContainer/VBoxContainer/Title

var _effect_time := 0.0
var _buttons: Array[Button] = []
var _normal_styles: Array[StyleBoxFlat] = []
var _hover_styles: Array[StyleBoxFlat] = []

func _ready() -> void:
	# Разрешаем узлу работать, даже когда вся игра на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Прячем меню при старте уровня
	visible = false
	_gather_styles()
	_setup_button_effects()


func _process(delta: float) -> void:
	if not visible:
		return
	_effect_time += delta
	_apply_ink_style()


func _apply_ink_style() -> void:
	var pulse := 0.5 + 0.5 * sin(_effect_time * 1.1)
	var pulse_slow := 0.5 + 0.5 * sin(_effect_time * 0.43 + 1.7)
	var black := Color(0.05, 0.05, 0.05, 1.0)
	var gray := Color(0.45, 0.45, 0.45, 1.0)

	title.add_theme_color_override("font_color", black.lerp(gray, pulse))
	title.add_theme_color_override("font_shadow_color", Color(0.55, 0.55, 0.55, 0.45))
	title.rotation = sin(_effect_time * 0.7) * 0.015 + sin(_effect_time * 1.9) * 0.005

	for i in _normal_styles.size():
		_normal_styles[i].border_color = black.lerp(gray, pulse)
		_hover_styles[i].border_color = black


func _gather_styles() -> void:
	for child in $CenterContainer/VBoxContainer.get_children():
		if child is Button:
			_buttons.append(child)
			_normal_styles.append(child.get_theme_stylebox("normal") as StyleBoxFlat)
			_hover_styles.append(child.get_theme_stylebox("hover") as StyleBoxFlat)


func _setup_button_effects() -> void:
	for button in _buttons:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.resized.connect(_update_pivot.bind(button))
		_update_pivot(button)


func _update_pivot(node: Control) -> void:
	node.pivot_offset = node.size / 2.0


func _input(event: InputEvent) -> void:
	# Esc снимает паузу только из видимого меню (открывает его игрок)
	if event.is_action_pressed("ui_cancel") and visible:
		_close_self()


func open() -> void:
	visible = true
	_effect_time = 0.0
	var menu_box := $CenterContainer/VBoxContainer
	menu_box.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(menu_box, "modulate:a", 1.0, 0.25)
	$CenterContainer/VBoxContainer/ResumeButton.grab_focus()


func close() -> void:
	visible = false


func _close_self() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_button_hovered(button: Button) -> void:
	var tween := create_tween()
	var anim := tween.tween_property(button, "scale", Vector2(1.06, 1.06), 0.12)
	anim.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_button_unhovered(button: Button) -> void:
	var tween := create_tween()
	var anim := tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	anim.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_resume_button_pressed() -> void:
	_close_self() # Снимет паузу и спрячет меню


func _on_exit_the_menu_button_pressed() -> void:
	get_tree().paused = false # На всякий случай снимаем паузу перед сменой сцены
	get_tree().change_scene_to_packed(exit_the_menu)
