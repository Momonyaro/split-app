extends Panel

@onready var avatar_rect: TextureRect = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/PanelContainer/TextureRect;
@onready var contact_name_label: Label = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/Label;
@onready var created_at_label: Label = $VBoxContainer/Label;

var popover_parent: PopoverMenu; # Will be assigned by parent

func _ready():
	var contact_id = popover_parent.subsection_keys[0];
	var contact = SQL.contact_utils.get_contact_by_id(contact_id);

	contact_name_label.text = contact.get_name();

	var date = contact.get_created_at();
	created_at_label.text = str(" > Created: ", date.year, "-", "%02d" % date.month, "-", "%02d" % date.day, " ", "%02d" % date.hour, ":", "%02d" % date.minute, ":", "%02d" % date.second);

	if contact.img_avatar == null:
		avatar_rect.get_parent().add_child(ImageUtils.get_default_avatar(contact, ImageUtils.AvatarSize.MEDIUM));
	else:
		avatar_rect.texture = ImageTexture.create_from_image(contact.get_avatar());
