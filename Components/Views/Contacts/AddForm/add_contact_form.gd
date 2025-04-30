extends Panel

@onready var id_label = $VBoxContainer/Label;
@onready var given_name_field: TextField = $VBoxContainer/NameField;
@onready var family_name_field: TextField = $VBoxContainer/FamilyField;
@onready var file_dialog = $FileDialog;
@onready var avatar_texrect = $VBoxContainer/HBoxContainer/Panel/TextureRect;
@onready var rotate_button = $VBoxContainer/HBoxContainer/Panel/img_rotate;
@onready var remove_button = $VBoxContainer/HBoxContainer/Panel/img_remove;

var popover_parent: PopoverMenu; # Will be assigned by parent

var form_data = {
	"id": "",
	"name_given": "",
	"name_family": "",
	"img_avatar": null
};

func _ready():
	OS.request_permissions();
	form_data["id"] = IDUtils.create_id("CTACT");
	file_dialog.file_selected.connect(_on_avatar_uploaded);
	remove_button.pressed.connect(_on_img_remove_pressed);
	given_name_field.value_changed.connect(_on_given_name_field_text_changed);
	family_name_field.value_changed.connect(_on_family_name_field_text_changed);

	id_label.text = str('id -> ', form_data["id"]);

func _process(_delta):
	rotate_button.visible = form_data.img_avatar != null;
	remove_button.visible = form_data.img_avatar != null;

func _on_family_name_field_text_changed(new_text:String):
	form_data["name_family"] = new_text.strip_edges();
	pass # Replace with function body.

func _on_given_name_field_text_changed(new_text:String):
	form_data["name_given"] = new_text.strip_edges();
	pass # Replace with function body.

func _validate_form() -> bool:
	var is_valid = true;
	given_name_field.error_message = "";
	family_name_field.error_message = "";

	if form_data["name_given"] == "":
		given_name_field.error_message = "Given name is required.";
		is_valid = false;
	if form_data["name_family"] == "":
		family_name_field.error_message = "Family name is required.";
		is_valid = false;
	return is_valid;

func _on_submit():
	if !_validate_form():
		return;

	var success = SQL.contact_utils.add_contact(form_data);
	if success:
		await popover_parent._t_close_menu();
	else:
		# Display error message
		push_error("Failed to add contact.");
		pass;

	pass # Replace with function body.

func _on_cancel_pressed():
	await popover_parent._t_close_menu();

func _on_avatar_upload_pressed():
	file_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES);
	file_dialog.show();
	pass # Replace with function body.

func _on_avatar_uploaded(file_path: String):
	var file = FileAccess.get_file_as_bytes(file_path);

	var img_tex = ImageTexture.create_from_image(ImageUtils._file_data_to_image(file));
	avatar_texrect.texture = img_tex;

	form_data["img_avatar"] = ImageUtils.pack_img_data(img_tex.get_image());
	pass # Replace with function body.


func _on_img_rotate_pressed() -> void:
	var img = (avatar_texrect.texture as ImageTexture).get_image();
	img.rotate_90(COUNTERCLOCKWISE);
	avatar_texrect.texture = ImageTexture.create_from_image(img);
	form_data.img_avatar = ImageUtils.pack_img_data(img);
	pass # Replace with function body.

func _on_img_remove_pressed() -> void:
	avatar_texrect.texture = null;
	form_data.img_avatar = null;
	pass # Replace with function body.
