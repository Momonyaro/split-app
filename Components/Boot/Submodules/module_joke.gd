extends Node;
class_name ModuleJokeText;

@export var joke_text: String = "Rolling dice...";

func setup(bootstrap: Node):
	bootstrap.log_message(joke_text);
	await get_tree().create_timer(0.5).timeout;
