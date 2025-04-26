extends Node
class_name ModuleDBInitContacts;

func setup(bootstrap: Node):
	bootstrap.log_message("> Running ModuleDBInitContacts...");

	# Check if contacts table exists and if not, create it.
	SQL.query("
		SELECT name FROM sqlite_master WHERE type='table'
	");
	var table_names = SQL.get_query_result().map(func (x): return x.name);

	if not table_names.has("contacts"):
		SQL.query("
			CREATE TABLE contacts (
				id varchar(255) NOT NULL,
				deleted boolean NOT NULL DEFAULT false,
				name_given varchar(255) NOT NULL DEFAULT 'John',
				name_family varchar(255) NOT NULL DEFAULT 'Doe',
				created_at varchar(255),
				img_avatar blob,
				PRIMARY KEY (id)
			)
		");

	await get_tree().create_timer(0.15).timeout;
