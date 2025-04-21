class_name SQLContactsUtils;

func get_contacts() -> Array:
    SQL.query("
    	SELECT * FROM contacts
    ");

    return SQL.get_query_result();
