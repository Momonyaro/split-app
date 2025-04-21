extends Control

@export var views: Dictionary[String, PackedScene] = {}

@onready var view_container = $ProgramContainer/VBoxContainer/ContentContainer;
@onready var navigation = $ProgramContainer/VBoxContainer/FooterContainer;
@onready var popover_container = $PopoverContainer;

var popover_prefab: PackedScene = preload("res://Components/Popover/popover_panel.tscn");
var popover_stack = [];

func _ready():
	navigation.on_nav_changed.connect(_on_nav_changed);

	var default_view_key = navigation.default_section;
	change_view(default_view_key);
	pass;

func change_view(view_key: String):
	if views.has(view_key):
		var view = views[view_key].instantiate();
		view.hide();

		for child in view_container.get_children():
			child.queue_free();

		view_container.add_child(view);

		view.show();
		await _tween_view();
	else:
		print("View not found");

func show_popover(title: String, view_key: String):
	if views.has(view_key):
		var packed_view: PackedScene = views[view_key];
		var popover_instance = popover_prefab.instantiate() as PopoverMenu;
		popover_instance.menu_contents = packed_view;
		popover_instance.set_title(title);

		popover_container.add_child(popover_instance);

		popover_stack.append(popover_instance);
	else:
		print("View not found");

func pop_popover():
	if popover_stack.is_empty():
		return;

	var popover = popover_stack.pop_back();
	popover.queue_free();

func _tween_view():
	view_container.get_child(0).size = view_container.size;
	var origo = Vector2(0, 32);
	await create_tween().tween_method(func(t):
		view_container.get_child(0).position = origo + Vector2(0, 24 * (1.0 - t));
		view_container.get_child(0).modulate = Color(1, 1, 1, t);
	, 0., 1., 0.2).finished;
	view_container.get_child(0).position = origo + Vector2(0, 0);
	view_container.get_child(0).modulate = Color(1, 1, 1, 1);

func _on_nav_changed(key: StringName):
	change_view(key);

func _on_settings_pressed():
	show_popover("Settings", 'nav-settings');
	pass # Replace with function body.
