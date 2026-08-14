extends Control

@onready var game_scene := preload("res://scenes/levels/test_level/test_level.tscn")
@onready var title: Label = $CenterContainer/VBoxContainer/Title

func _ready() -> void:
	_fade_in_menu()
	_setup_button_effects()
	_animate_title()
	$CenterContainer/VBoxContainer/PlayButton.grab_focus()


func _fade_in_menu() -> void:
	var menu_box := $CenterContainer/VBoxContainer
	menu_box.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_box, "modulate:a", 1.0, 0.5)


func _setup_button_effects() -> void:
	var buttons := $CenterContainer/VBoxContainer.get_children().filter(func(c): return c is Button)
	for button in buttons:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.resized.connect(_update_pivot.bind(button))
		_update_pivot(button)
	_update_pivot(title)


func _animate_title() -> void:
	var tween := create_tween().set_loops()
	var grow := tween.tween_property(title, "scale", Vector2(1.03, 1.03), 1.8)
	grow.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var shrink := tween.tween_property(title, "scale", Vector2.ONE, 1.8)
	shrink.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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
