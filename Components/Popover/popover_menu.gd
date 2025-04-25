extends PanelContainer
class_name PopoverMenu

@onready var content_parent = $ProgramContainer/VBoxContainer/ContentContainer;
@onready var back_btn = $ProgramContainer/VBoxContainer/Header/Button;

var tween_duration = 0.15;
var menu_contents: PackedScene;
var subsection_keys: Array;

func _ready():
	position.x = get_parent().size.x + 2;
	back_btn.pressed.connect(_t_close_menu);
	var children = content_parent.get_children();

	for child in children:
		child.queue_free();

	if menu_contents != null:
		var menu = menu_contents.instantiate();
		menu.popover_parent = self;
		content_parent.add_child(menu);

	await _t_open_menu();

func _process(_delta):
	size = get_parent().size;

func set_title(title: String):
	$ProgramContainer/VBoxContainer/Header/Label.text = title;

func set_subsection(keys: Array):
	subsection_keys = keys;

func _t_open_menu():
	await create_tween().tween_property(self, "position", Vector2.ZERO, tween_duration).finished;

func _t_close_menu():
	await create_tween().tween_property(self, "position", Vector2(size.x + 2, 0), tween_duration).finished;
	var view_manager = get_tree().get_first_node_in_group("$VIEW_MANAGER");
	view_manager.pop_popover();
