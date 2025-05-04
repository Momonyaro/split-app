class_name SQLPaymentUtils;

signal payments_modified(payment_id: String);

func get_payment(payment_id: String) -> Payment: # Not scalable, but I'm no SQL wizard...
	SQL.query_with_bindings("SELECT * FROM payments WHERE id = ?", [payment_id]);
	var payment_result = SQL.get_query_result();
	if payment_result.size() == 0:
		return null;

	SQL.query_with_bindings("SELECT * FROM payment_participants WHERE payment_id = ?", [payment_id]);
	var participants = SQL.get_query_result();

	SQL.query_with_bindings("SELECT * FROM payment_line_items WHERE payment_id = ?", [payment_id]);
	var line_items = SQL.get_query_result();

	var payment = Payment.new(payment_result[0]);
	payment.participants = participants.map(func (x): return PaymentParticipant.new(x));
	payment.line_items = line_items.map(func (x): return LineItem.new(x));
	for i in payment.line_items.size():
		var line_item = payment.line_items[i];
		SQL.query_with_bindings("SELECT * FROM payment_line_item_participants WHERE line_item_id = ?", [line_item.id]);
		var line_item_participants = SQL.get_query_result();
		line_item.participants = line_item_participants.map(func (x): return LineItemParticipant.new(x));
		payment.line_items[i] = line_item;

	return payment;

func get_payments() -> Array:
	SQL.query("
		SELECT id FROM payments
		WHERE deleted = false;
	");
	var payment_ids = SQL.get_query_result();

	var result = [];
	for id in payment_ids:
		var payment = get_payment(id.id);
		if payment != null:
			result.append(payment);
	return result;

func add_payment(form_data: Dictionary):
	SQL.query("BEGIN TRANSACTION;");

	# Upsert payment using SQL query
	SQL.query_with_bindings(
		"INSERT INTO payments VALUES (?, ?, ?, ?, ?)",
		[form_data["id"], false, form_data["title"], form_data["currency"], Time.get_datetime_string_from_system()]
	);

	# Add Participants
	for participant in form_data["participants"]:
		SQL.query_with_bindings(
			"INSERT INTO payment_participants VALUES (?, ?, ?)",
			[participant.id, form_data["id"], participant.contact_id]
		);

	for line_item in form_data["line_items"]:
		SQL.query_with_bindings(
			"INSERT INTO payment_line_items VALUES (?, ?, ?, ?, ?)",
			[line_item.id, false, form_data["id"], line_item.title, line_item.amount_cents]
		);

		for line_participant in line_item.participants:
			SQL.query_with_bindings(
				"INSERT INTO payment_line_item_participants VALUES (?, ?, ?, ?, ?)",
				[line_participant.id, line_item.id, line_participant.participant_id,
					line_participant.fixed_amount_cents, line_participant.fixed_amount_percentage]
			);
		pass;

	SQL.query("COMMIT;");
	payments_modified.emit(form_data["id"]);

func delete_payment(payment_id: String):
	SQL.query_with_bindings("UPDATE payments SET deleted = TRUE WHERE id = ?", [payment_id]);

	payments_modified.emit(payment_id);

class Payment:
	var id: String;
	var title: String;
	var deleted: bool;
	var currency: String;
	var created_at: String;

	var line_items: Array;
	var participants: Array;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.deleted = dict.get("deleted", false);
		self.title = dict["title"];
		self.currency = dict["currency"];
		self.created_at = dict["created_at"];
		var parsed_line_items = JSON.parse_string(dict.get("line_items_array", '[]'));
		self.line_items = [];
		for item in parsed_line_items:
			self.line_items.append(LineItem.new(item));

	func get_total_amount_cents() -> int:
		var total = 0;
		for item in self.line_items:
			total += item.amount_cents;
		return total;

	func get_created_at() -> Dictionary:
		return Time.get_datetime_dict_from_datetime_string(created_at, false);

class PaymentParticipant:
	var id: String;
	var payment_id: String;
	var contact_id: String;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.payment_id = dict["payment_id"];
		self.contact_id = dict["contact_id"];

class LineItem:
	var id: String;
	var payment_id: String;
	var title: String;
	var amount_cents: int;

	var participants: Array;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.title = dict["title"];
		self.payment_id = dict["payment_id"];
		self.amount_cents = dict["amount_cents"];

class LineItemParticipant:
	var id: String;
	var line_item_id: String;
	var participant_id: String;
	var fixed_amount_cents;
	var fixed_amount_percentage;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.line_item_id = dict["line_item_id"];
		self.participant_id = dict["participant_id"];
		self.fixed_amount_cents = dict["fixed_amount_cents"];
		self.fixed_amount_percentage = dict["fixed_amount_percentage"];

	func has_fixed_percentage() -> bool:
		return self.fixed_amount_percentage != null;

	func has_fixed_amount() -> bool:
		return self.fixed_amount_cents != null;

	func has_fixed_amount_or_percentage() -> bool:
		return self.has_fixed_amount() || self.has_fixed_percentage();
