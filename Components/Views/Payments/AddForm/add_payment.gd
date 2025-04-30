extends Panel

var popover_parent;
var contacts = [];

@onready var participant_menu: MenuButton = $VBoxContainer/MenuButton;
@onready var cancel_button: Button = $MarginContainer/Buttons/Cancel;
@onready var title_field: TextField = $VBoxContainer/TextField;
@onready var id_label: Label = $VBoxContainer/IDLabel;

var form_data = {
	"id": IDUtils.create_id('PAYMT'),
	"title": "New Payment",
	"participants": []
};

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed);
	title_field.value_changed.connect(_on_title_changed);
	participant_menu.get_popup().id_pressed.connect(_on_participant_selected);

	populate();

func _process(_delta: float) -> void:
	participant_menu.get_popup().position.y = floori(participant_menu.global_position.y + participant_menu.size.y + 8);

func populate():
	title_field.overwrite_value(form_data["title"]);
	id_label.text = str('ID -> ', form_data["id"]);
	contacts = SQL.contact_utils.get_contacts();

	populate_participants();
	pass;

func populate_participants():
	var current_participants = form_data["participants"];
	var popup = participant_menu.get_popup();
	popup.clear();

	participant_menu.disabled = false;
	if contacts.size() == 0:
		participant_menu.disabled = true;

	var no_available_participants = true;
	for i in contacts.size():
		var contact = contacts[i];
		var reserved = current_participants.filter(func (p): return p["id"] == contact["id"]).size() > 0;
		if !reserved:
			no_available_participants = false;

		var has_avatar = contact.img_avatar != null;

		if has_avatar:
			popup.add_icon_item(ImageTexture.create_from_image(contact.get_avatar()), contact.get_name(), i);
		else:
			popup.add_item(contact.get_name(), i);

		popup.set_item_disabled(i, reserved);
		popup.set_item_as_checkable(i, reserved);
		popup.set_item_checked(i, reserved);

	if no_available_participants:
		participant_menu.disabled = true;

	for participant in form_data.participants:
		print(participant.id);
	pass;

func _on_title_changed(new_title: String):
	form_data["title"] = new_title;
	title_field.error_message = "Title cannot be empty" if new_title.length() == 0 else "";

func _on_participant_selected(id: int):
	form_data["participants"].push_back(contacts[id]);
	populate();

func _on_cancel_pressed():
	await popover_parent._t_close_menu();
