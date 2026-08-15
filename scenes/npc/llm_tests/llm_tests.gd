extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AiController.send_messege("Привет, тестирую апи!")
	$AiController.connect("response_completed", _responce)
	await $AiController.response_completed

func _responce(message: Message):
	printt(message.content)
