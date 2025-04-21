extends PanelContainer

@export var label_settings: LabelSettings;
@export var active_label_settings: LabelSettings;
var callback: Callable;
var item_key: StringName;
var nav_item: Dictionary;
var is_active: bool;

func update(_is_active: bool):
	is_active = _is_active;

	var icon_path = nav_item.active_icon_ref if is_active else nav_item.icon_ref;
	$VBoxContainer/TextureRect.texture = ResourceLoader.load(icon_path);
	$VBoxContainer/Label.label_settings = active_label_settings if is_active else label_settings;

	var tween = create_tween().bind_node(self)
	tween.tween_property($Mask/Background, "modulate", Color.WHITE if is_active else Color.TRANSPARENT, .15)

func populate(_nav_item: Dictionary, _is_active: bool, _callback: Callable):
	nav_item = _nav_item;
	is_active = _is_active;
	item_key = nav_item.key;
	callback = _callback;
	
	var icon_path = nav_item.active_icon_ref if is_active else nav_item.icon_ref;
	$VBoxContainer/TextureRect.texture = ResourceLoader.load(icon_path);
	$VBoxContainer/Label.text = nav_item.title;
	$VBoxContainer/Label.label_settings = active_label_settings if is_active else label_settings;

	var tween = create_tween().bind_node(self)
	tween.tween_property($Mask/Background, "modulate", Color.WHITE if is_active else Color.TRANSPARENT, .15)

func _on_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		callback.call(item_key);
	pass # Replace with function body.
