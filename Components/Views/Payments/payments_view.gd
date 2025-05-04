extends Panel

@export var list_item_prefab: PackedScene = preload("res://Components/Views/Payments/payment_list_item.tscn");
@export var no_content_prefab: PackedScene = preload("res://Components/Views/Contacts/no_content_item.tscn");

@onready var payments_list = $VBoxContainer/ScrollContainer/PanelContainer/VBoxContainer;
@onready var sorting_menu: MenuButton = $VBoxContainer/MarginContainer/HBoxContainer/MenuButton;
@onready var floating_button: FloatingButton = $FloatingButton;


func _ready():
	var view_manager = get_tree().get_first_node_in_group("$VIEW_MANAGER");

	floating_button.pressed.connect(func():
		view_manager.show_popover('Add Payment', 'nav-add-payment');
	);

	SQL.payment_utils.payments_modified.connect(func(_x):
		populate();
	);

	setup_sorting();
	populate();

func populate():
	var payments = SQL.payment_utils.get_payments();

	var id = PersistentData.try_get_persistent(PersistentData.PAYMENTS_SORT);
	match id:
		2:
			payments.sort_custom(func(a, b):
				return a.title < b.title
			);
		3:
			payments.sort_custom(func(a, b):
				return a.title > b.title
			);

	for child in payments_list.get_children():
		child.queue_free();

	if payments.size() == 0:
		sorting_menu.disabled = true;
		var no_content_item = no_content_prefab.instantiate();
		payments_list.add_child(no_content_item);
	else:
		sorting_menu.disabled = false;
		for payment in payments:
			var payment_item = list_item_prefab.instantiate();
			payment_item.populate(payment);
			payments_list.add_child(payment_item);

	_create_padding();

func setup_sorting():
	var popup: PopupMenu = sorting_menu.get_popup();
	popup.prefer_native_menu = true;

	var id = PersistentData.try_get_persistent(PersistentData.PAYMENTS_SORT);
	var last_index = popup.get_item_index(id);
	if last_index != -1:
		popup.set_item_checked(last_index, true);

	popup.id_pressed.connect(_on_sorting_menu_id_pressed);

func _on_sorting_menu_id_pressed(id: int):
	var popup: PopupMenu = sorting_menu.get_popup();
	var last_index = PersistentData.try_get_persistent(PersistentData.PAYMENTS_SORT);
	var current_index = popup.get_item_index(id);

	if last_index != -1:
		popup.set_item_checked(last_index, false);
	if current_index != -1:
		popup.set_item_checked(current_index, true);

	PersistentData.write_persistent(PersistentData.PAYMENTS_SORT, id);
	populate();

func _create_padding():
	var padding = BoxContainer.new()
	padding.set_custom_minimum_size(Vector2(0, 128));
	payments_list.add_child(padding)
