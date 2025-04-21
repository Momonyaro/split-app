class_name SQLContactsUtils;

signal contact_added(contact_id: String);

func get_contacts() -> Array:
    SQL.query("
    	SELECT * FROM contacts
    ");

    return SQL.get_query_result();

func add_contact(contact: Dictionary) -> bool:
    var success = SQL.query_with_bindings("
    	INSERT INTO contacts (id, name_family, name_given, img_avatar)
    	VALUES (?, ?, ?, ?)
    ", [contact.id, contact.name_family, contact.name_given, contact.img_avatar]);

    if success:
        contact_added.emit(contact.id);
    return success;
