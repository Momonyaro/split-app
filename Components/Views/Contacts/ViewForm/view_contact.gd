extends Panel

@onready var avatar_rect: TextureRect = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/PanelContainer/TextureRect;
@onready var contact_name_label: Label = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/Label;
@onready var created_at_label: Label = $VBoxContainer/Label;
@onready var delete_button: Button = $VBoxContainer/Buttons/Delete;
@onready var edit_button: Button = $VBoxContainer/Buttons/Edit;


var prompt = preload("res://Components/Prompt/delete_prompt.tscn");
var popover_parent: PopoverMenu; # Will be assigned by parent
var contact: SQLContactsUtils.Contact;

func _ready():
	var view_manager = get_tree().get_first_node_in_group("$VIEW_MANAGER");
	var contact_id = popover_parent.subsection_keys[0];
	contact = SQL.contact_utils.get_contact_by_id(contact_id);

	SQL.contact_utils.contacts_changed.connect(_on_contacts_changed);

	delete_button.pressed.connect(func():
		var delete_prompt = prompt.instantiate();
		get_tree().root.add_child(delete_prompt);
		delete_prompt.set_explode_action(_on_explosion);
		delete_prompt.set_fuse_length(1.0);
	);

	edit_button.pressed.connect(func():
		view_manager.show_popover("Edit Contact", str('nav-edit-contact/', contact_id))
	);

	populate();

func _exit_tree():
	SQL.contact_utils.contacts_changed.disconnect(_on_contacts_changed);

func populate():
	contact_name_label.text = contact.get_name();

	var date = contact.get_created_at();
	created_at_label.text = str(" > Created: ", date.year, "-", "%02d" % date.month, "-", "%02d" % date.day, " ", "%02d" % date.hour, ":", "%02d" % date.minute, ":", "%02d" % date.second);

	var children = avatar_rect.get_parent().get_children();
	for i in children.size():
		if i == 0:
			continue;
		children[i].queue_free();

	if contact.img_avatar == null:
		avatar_rect.get_parent().add_child(ImageUtils.get_default_avatar(contact, ImageUtils.AvatarSize.MEDIUM));
	else:
		avatar_rect.texture = ImageTexture.create_from_image(contact.get_avatar());

func _on_explosion():
	SQL.contact_utils.delete_contact(contact.id);
	popover_parent._t_close_menu();

func _on_contacts_changed(id):
	if id == contact.id:
		contact = SQL.contact_utils.get_contact_by_id(contact.id);
		populate();
