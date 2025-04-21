extends Node;
class_name ModuleDBInit;

func setup(bootstrap: Node):
	bootstrap.log_message("> Running ModuleDBInit...");

	if !FileAccess.file_exists(SQL.DATASTORE_PATH):
		var file = FileAccess.open(SQL.DATASTORE_PATH, FileAccess.WRITE);
		file.close();

	await get_tree().create_timer(0.15).timeout;
