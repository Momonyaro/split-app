extends Panel

@export var list_item_prefab: PackedScene = preload("res://Components/Views/Contacts/contact_list_item.tscn");
@export var no_content_prefab: PackedScene = preload("res://Components/Views/Contacts/no_content_item.tscn");

@onready var contacts_list = $VBoxContainer/ScrollContainer/PanelContainer/VBoxContainer;
@onready var sorting_menu: MenuButton = $VBoxContainer/MarginContainer/HBoxContainer/MenuButton;
@onready var floating_button: FloatingButton = $FloatingButton;

func _ready():
	var view_manager = get_tree().get_first_node_in_group("$VIEW_MANAGER");
	floating_button.pressed.connect(func():
		view_manager.show_popover("Add Contact", 'nav-add-contact')
	);

	SQL.contact_utils.contact_added.connect(_on_contact_added);

	setup_sorting();
	populate();

func _exit_tree():
	SQL.contact_utils.contact_added.disconnect(_on_contact_added);

func populate():
	var contacts = SQL.contact_utils.get_contacts();

	var id = PersistentData.try_get_persistent("contacts.sort");
	match id:
		0:
			contacts.sort_custom(func(a, b):
				return a.name_given < b.name_given
			);
		1:
			contacts.sort_custom(func(a, b):
				return a.name_given > b.name_given
			);

	for child in contacts_list.get_children():
		child.queue_free();

	if contacts.size() == 0:
		sorting_menu.disabled = true;
		var no_content_item = no_content_prefab.instantiate();
		contacts_list.add_child(no_content_item);
	else:
		sorting_menu.disabled = false;
		for contact in contacts:
			var contact_item = list_item_prefab.instantiate();
			contact_item.populate(contact);
			contacts_list.add_child(contact_item);

	_create_padding();

func setup_sorting():
	var popup: PopupMenu = sorting_menu.get_popup();
	popup.prefer_native_menu = true;

	var id = PersistentData.try_get_persistent("contacts.sort");
	var last_index = popup.get_item_index(id);
	if last_index != -1:
		popup.set_item_checked(last_index, true);

	popup.id_pressed.connect(_on_sorting_menu_id_pressed);

func _on_sorting_menu_id_pressed(id: int):
	var popup: PopupMenu = sorting_menu.get_popup();
	var last_index = PersistentData.try_get_persistent("contacts.sort");
	var current_index = popup.get_item_index(id);

	if last_index != -1:
		popup.set_item_checked(last_index, false);
	if current_index != -1:
		popup.set_item_checked(current_index, true);

	PersistentData.write_persistent("contacts.sort", id);
	populate();

func _create_padding():
	var padding = BoxContainer.new()
	padding.set_custom_minimum_size(Vector2(0, 128));
	contacts_list.add_child(padding)

func _on_contact_added(_id: String):
	populate();
