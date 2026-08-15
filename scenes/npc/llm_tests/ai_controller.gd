extends Node
class_name AiController
signal response_completed

var open_ai: OpenAI

@export var system_prompt: String

var context: Array[Message]

# Called when the node enters the scene tree for the first time.
func _ready():
	open_ai = OpenAI.new()
	add_child(open_ai)
	
	context.append(Message.new())
	
	context[-1].set_role('system')
	context[-1].set_content(system_prompt)
	
	##Conecting the output from chatgpt
	open_ai.connect("gpt_response_completed", gpt_response_completed)
	
	###Creating meessages template
	#var messages: Array[Message] = [Message.new()]
	#messages[0].set_content("say hi!")
#
	###Prompt chatgpt
	#open_ai.prompt_gpt(messages, Config.model_name)



func send_messege(messege: String) -> void:
	context.append(Message.new())
	context[-1].set_content(messege)
	open_ai.prompt_gpt(context, Config.model_name)



@warning_ignore("unused_parameter")
func gpt_response_completed(message: Message, response: Dictionary):
	emit_signal("response_completed", message)
