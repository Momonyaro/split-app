extends PanelContainer

const nav_data = &"res://Data/nav_data.json";

signal on_nav_changed(key: StringName);

@export var default_section := &"nav-home";
@export var list_item_prefab = preload("res://Components/Footer/footer_item.tscn");
@onready var list_parent = $Footer;

var current_section = default_section;

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout;
	draw_list();

func draw_list():
	_clear_list();
	var dict = readJSON(nav_data);
	for item in dict.get("items"):
		var instance = list_item_prefab.instantiate();
		instance.populate(item, current_section == item.key, on_nav_item_selected);
		list_parent.add_child(instance);

func update_list():
	for child in list_parent.get_children():
		child.update(current_section == child.item_key);

func _clear_list() -> void:
	for child in list_parent.get_children():
		child.queue_free();

func on_nav_item_selected(item_key: StringName):
	if current_section != item_key:
		on_nav_changed.emit(item_key);
		if PersistentData.try_get_persistent(PersistentData.SETTING_VIBRATE):
			Input.vibrate_handheld(50, .2); # Slight vibration for device feedback
	current_section = item_key;
	update_list();

func readJSON(jsonFilePath):
	var file = FileAccess.open(jsonFilePath, FileAccess.READ)
	var content = file.get_as_text()

	var finish = JSON.parse_string(content)
	return finish
