extends Panel

var popover_parent;
var contacts = [];

@onready var participant_menu: MenuButton = $VBoxContainer/MenuButton;
@onready var cancel_button: Button = $MarginContainer/Buttons/Cancel;

var form_data = {
	"title": "",
	"participants": []
};

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed);
	participant_menu.get_popup().id_pressed.connect(_on_participant_selected);

	populate();

func _process(_delta: float) -> void:
	participant_menu.get_popup().position.y = floori(participant_menu.global_position.y + participant_menu.size.y + 8);

func populate():
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
		return;

	for i in contacts.size():
		var contact = contacts[i];
		var reserved = current_participants.filter(func (p): return p["id"] == contact["id"]).size() > 0;
		var has_avatar = contact.img_avatar != null;

		if has_avatar:
			popup.add_icon_item(ImageTexture.create_from_image(contact.get_avatar()), contact.get_name(), i);
		else:
			popup.add_item(contact.get_name(), i);

		popup.set_item_disabled(i, reserved);
		popup.set_item_as_checkable(i, reserved);
		popup.set_item_checked(i, reserved);


	pass;


func _on_participant_selected(id: int):
	form_data["participants"].push_back(contacts[id]);
	populate();

func _on_cancel_pressed():
	await popover_parent._t_close_menu();
