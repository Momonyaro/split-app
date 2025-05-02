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
	for line_item in line_items:
		SQL.query_with_bindings("SELECT * FROM payment_line_item_participants WHERE line_item_id = ?", [line_item.id]);
		var line_item_participants = SQL.get_query_result();
		line_item.participants = line_item_participants.map(func (x): return LineItemParticipant.new(x));

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
	var title: String;
	var amount_cents: int;

	var participants: Array;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.title = dict["title"];
		self.amount_cents = dict["amount_cents"];

class LineItemParticipant:
	var id: String;
	var line_item_id: String;
	var participant_id: String;
	var fixed_amount_cents: int;
	var fixed_amount_percentage: int;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.line_item_id = dict["line_item_id"];
		self.participant_id = dict["participant_id"];
		self.fixed_amount_cents = dict["fixed_amount_cents"];
		self.fixed_amount_percentage = dict["fixed_amount_percentage"];
