extends Node
class_name ModuleDBInitPaymentLineItems;

func setup(bootstrap: Node):
	bootstrap.log_message("> Running init for Payment Line Items...");

	# Check if payment line items table exists and if not, create it.
	SQL.query("
		SELECT name FROM sqlite_master WHERE type='table'
	");
	var table_names = SQL.get_query_result().map(func (x): return x.name);

	if not table_names.has("payment_line_items"):
		SQL.query("
			CREATE TABLE payment_line_items (
				id varchar(255) NOT NULL,
				deleted boolean NOT NULL DEFAULT false,
				payment_id varchar(255) NOT NULL,
				title varchar(255) NOT NULL,
				amount_cents integer NOT NULL,
				PRIMARY KEY (id),
				FOREIGN KEY (payment_id) REFERENCES payments(id)
			)
		");

	if not table_names.has("payment_line_item_participants"):
		SQL.query("
			CREATE TABLE payment_line_item_participants (
				id varchar(255) NOT NULL,
				line_item_id varchar(255) NOT NULL,
				participant_id varchar(255) NOT NULL,
				fixed_amount_cents integer,
				fixed_amount_percentage integer,
				PRIMARY KEY (id),
				FOREIGN KEY (line_item_id) REFERENCES payment_line_items(id),
				FOREIGN KEY (participant_id) REFERENCES payment_participants(id)
			)
		");

	await get_tree().create_timer(0.15).timeout;
