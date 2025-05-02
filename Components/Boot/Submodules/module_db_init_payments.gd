extends Node
class_name ModuleDBInitPayments;

func setup(bootstrap: Node):
	bootstrap.log_message("> Running init for Payments...");

	# Check if payments table exists and if not, create it.
	SQL.query("
		SELECT name FROM sqlite_master WHERE type='table'
	");
	var table_names = SQL.get_query_result().map(func (x): return x.name);

	if not table_names.has("payments"):
		SQL.query("
			CREATE TABLE payments (
				id varchar(255) NOT NULL,
				deleted boolean NOT NULL DEFAULT false,
				title varchar(255) NOT NULL DEFAULT 'New Payment',
				currency varchar(255) NOT NULL DEFAULT 'SEK',
				created_at varchar(255),
				PRIMARY KEY (id)
			)
		");

	if not table_names.has("payment_participants"):
		SQL.query("
			CREATE TABLE payment_participants (
				id varchar(255) NOT NULL,
				payment_id varchar(255) NOT NULL,
				contact_id varchar(255) NOT NULL,
				PRIMARY KEY (id),
				FOREIGN KEY (payment_id) REFERENCES payments(id),
				FOREIGN KEY (contact_id) REFERENCES contacts(id)
			)
		");

	await get_tree().create_timer(0.15).timeout;
