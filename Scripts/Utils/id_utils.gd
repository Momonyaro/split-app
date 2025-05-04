class_name IDUtils;

static var internal_offset = 0;

static func create_id(id_prefix: String) -> String:
	var date_time = Time.get_datetime_string_from_system() + str(internal_offset);
	internal_offset = (internal_offset + 1) % 9999;
	var to_hash = date_time.md5_text().substr(0, 12);
	return str(id_prefix, '_', to_hash).to_upper();
