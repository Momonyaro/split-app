extends Panel


@onready var id_label = $VBoxContainer/Label;
@onready var given_name_field = $VBoxContainer/GivenName;
@onready var family_name_field = $VBoxContainer/FamilyName;
@onready var file_dialog = $FileDialog;
@onready var avatar_texrect = $VBoxContainer/HBoxContainer/Panel/TextureRect;

var popover_parent: PopoverMenu; # Will be assigned by parent

var form_data = {
	"id": "",
	"name_given": "",
	"name_family": "",
	"img_avatar": null
};

func _ready():
	form_data["id"] = _create_id();
	file_dialog.file_selected.connect(_on_avatar_uploaded);

	id_label.text = str('id -> ', form_data["id"]);

func _create_id() -> String:
	var date_time = Time.get_datetime_string_from_system();
	var to_hash = date_time.md5_text().substr(0, 8);
	return str('ctact_', to_hash).to_upper();

func _on_family_name_field_text_changed(new_text:String):
	form_data["name_family"] = new_text;
	pass # Replace with function body.

func _on_given_name_field_text_changed(new_text:String):
	form_data["name_given"] = new_text;
	pass # Replace with function body.

func _validate_form() -> bool:
	var is_valid = true;
	var given_name_error = given_name_field.get_child(0).get_child(-1);
	var family_name_error = family_name_field.get_child(0).get_child(-1);

	given_name_error.hide();
	family_name_error.hide();

	if form_data["name_given"] == "":
		given_name_error.text = "Given name is required.";
		given_name_error.show();
		is_valid = false;
	if form_data["name_family"] == "":
		family_name_error.text = "Family name is required.";
		family_name_error.show();
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

	form_data["img_avatar"] = file;
	pass # Replace with function body.
