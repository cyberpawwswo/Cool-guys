extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	tween.tween_method(_set_text, 20, 1, 6)
	tween.tween_callback(get_tree().change_scene_to_file.bind("res://scenes/ui/main_menu/main_menu.tscn"))


func _set_text(idx):
	$Disclaimer/Label2.text = str(idx) + " Или нажми пробел"


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
