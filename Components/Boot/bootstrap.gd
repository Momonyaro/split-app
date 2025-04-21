extends Control

@export var target_scene: PackedScene;
@export var wipe_existing_data: bool;
var modules = []

func _ready() -> void:
	await get_tree().create_timer(.5).timeout;
	for module in $Modules.get_children():
		await module.setup(self);
		modules.push_back(module);

	log_message("");
	log_message("Done!");
	await get_tree().create_timer(1).timeout;
	get_tree().change_scene_to_packed(target_scene);

func log_message(message: String) -> void:
	$MarginContainer/BootLog.write_line(message);
