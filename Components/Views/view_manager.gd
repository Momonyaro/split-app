extends Control

@export var views: Dictionary[String, PackedScene] = {}

@onready var view_container = $ProgramContainer/VBoxContainer/ContentContainer;
@onready var navigation = $ProgramContainer/VBoxContainer/FooterContainer;

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
