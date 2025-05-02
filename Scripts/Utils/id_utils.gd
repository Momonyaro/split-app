class_name IDUtils;

static func create_id(id_prefix: String) -> String:
	var date_time = Time.get_datetime_string_from_system();
	var to_hash = date_time.md5_text().substr(0, 12);
	return str(id_prefix, '_', to_hash).to_upper();
