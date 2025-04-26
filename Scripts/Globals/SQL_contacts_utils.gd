class_name SQLContactsUtils;

signal contacts_changed(contact_id: String);

func get_contact() -> Contact:
	SQL.query("
		SELECT * FROM contacts TAKE 1
	");

	var result = SQL.get_query_result();
	if result.is_empty():
		return null;
	return Contact.new(result[0]);

func get_contact_by_id(id: String) -> Contact:
	SQL.query_with_bindings("
		SELECT * FROM contacts WHERE id = ?
	", [id]);

	var result = SQL.get_query_result();
	if result.is_empty():
		return null;
	return Contact.new(result[0]);

func get_contacts() -> Array:
	SQL.query("
		SELECT * FROM contacts
		WHERE deleted = false
	");

	var result = SQL.get_query_result();
	var contacts = Array();

	for row in result:
		var contact = Contact.new(row);
		contacts.append(contact);

	return contacts;

func add_contact(contact: Dictionary) -> bool:
	var now = Time.get_datetime_string_from_system();

	var success = SQL.query_with_bindings("
		INSERT INTO contacts (id, name_family, name_given, created_at, img_avatar)
		VALUES (?, ?, ?, ?, ?)
	", [contact.id, contact.name_family, contact.name_given, now, contact.img_avatar]);

	if success:
		contacts_changed.emit(contact.id);
	return success;

func update_contact(contact: Dictionary) -> bool:
	var success = SQL.query_with_bindings("
		UPDATE contacts SET name_family = ?, name_given = ?, img_avatar = ?
		WHERE id = ?
	", [contact.name_family, contact.name_given, contact.img_avatar, contact.id]);

	if success:
		contacts_changed.emit(contact.id);
	return success;

func delete_contact(id: String) -> bool:
	var success = SQL.query_with_bindings("
		UPDATE contacts SET deleted = true, name_given = 'Deleted', name_family = 'Contact' WHERE id = ?
	", [id]);

	if success:
		contacts_changed.emit(id);
	return success;

class Contact:
	var id: String;
	var deleted: bool;
	var name_family: String;
	var name_given: String;
	var created_at: String;
	var img_avatar;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.deleted = dict.get("deleted", false);
		self.name_family = dict["name_family"];
		self.name_given = dict["name_given"];
		self.created_at = dict["created_at"];
		self.img_avatar = dict["img_avatar"];

	func get_name() -> String:
		return str(self.name_given, " ", self.name_family);

	func get_avatar() -> Image:
		var format = (img_avatar)[0];
		var img_data = (img_avatar).slice(1);

		return Image.create_from_data(256, 256, false, format, img_data);

	func get_created_at() -> Dictionary:
		return Time.get_datetime_dict_from_datetime_string(created_at, false);
