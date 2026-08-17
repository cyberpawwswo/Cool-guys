extends Control

@onready var game_scene := preload("res://scenes/levels/test_level/test_level.tscn")
@onready var title: Label = $CenterContainer/VBoxContainer/Title
@onready var subtitle: Label = $CenterContainer/VBoxContainer/Subtitle
@onready var footer: Label = $Footer

var _effect_time := 0.0
var _buttons: Array[Button] = []
var _normal_styles: Array[StyleBoxFlat] = []
var _hover_styles: Array[StyleBoxFlat] = []

func _ready() -> void:
	_restore_game_window()
	var tween = create_tween()
	tween.tween_method(_set_text, 20, 1, 6)
	tween.tween_callback($Disclaimer.queue_free)
	await tween.finished
	_gather_styles()
	_fade_in_menu()
	_setup_button_effects()
	$CenterContainer/VBoxContainer/PlayButton.grab_focus()


func _set_text(idx):
	$Disclaimer/Label2.text = str(idx)


func _restore_game_window() -> void:
	var window := get_window()
	window.mode = Window.MODE_FULLSCREEN
	window.grab_focus()

func _process(delta: float) -> void:
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
	title.scale = Vector2.ONE * (1.0 + pulse * 0.03 + pulse_slow * 0.02)
	title.modulate.a = 0.9 + pulse_slow * 0.1

	subtitle.add_theme_color_override(
		"font_color", Color(0.35, 0.35, 0.35, 0.9)
	)

	footer.add_theme_color_override(
		"font_color", Color(0.25, 0.25, 0.25, 0.45)
	)

	for i in _normal_styles.size():
		_normal_styles[i].border_color = black.lerp(gray, pulse)
		_hover_styles[i].border_color = black


func _gather_styles() -> void:
	for child in $CenterContainer/VBoxContainer.get_children():
		if child is Button:
			_buttons.append(child)
			_normal_styles.append(child.get_theme_stylebox("normal") as StyleBoxFlat)
			_hover_styles.append(child.get_theme_stylebox("hover") as StyleBoxFlat)


func _fade_in_menu() -> void:
	var menu_box := $CenterContainer/VBoxContainer
	menu_box.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_box, "modulate:a", 1.0, 0.5)


func _setup_button_effects() -> void:
	for button in _buttons:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.resized.connect(_update_pivot.bind(button))
		_update_pivot(button)
	_update_pivot(title)


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


func _on_play_button_pressed() -> void:
	var menu_box := $CenterContainer/VBoxContainer
	var tween := create_tween()
	tween.tween_property(menu_box, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_packed(game_scene))


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_audio_stream_player_finished() -> void:
	$AudioStreamPlayer.play()
