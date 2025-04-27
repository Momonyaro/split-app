class_name SQLPaymentUtils;

signal payments_modified(payment_id: String);

func get_payment(payment_id: String) -> Payment:
	var query = "SELECT * FROM payments WHERE id = ?";
	SQL.query_with_bindings(query, [payment_id]);
	var result = SQL.get_query_result();
	if result.size() == 0:
		return null;
	return Payment.new(result[0]);

func get_payments() -> Array:
	SQL.query("
		SELECT
		payments.*,
		JSON_GROUP_ARRAY(
			JSON_OBJECT(
				'id', line_items.id,
				'payment_id', line_items.payment_id,
				'title', line_items.title,
				'amount_cents', line_items.amount_cents
			)
		) as line_items_array
		FROM payments
		LEFT JOIN payment_line_items as line_items ON payments.id = line_items.payment_id
		WHERE payments.deleted = false and line_items.deleted = false
	");
	var result = SQL.get_query_result();
	var payments = [];
	for row in result:
		payments.append(Payment.new(row));
	return payments;

class Payment:
	var id: String;
	var title: String;
	var deleted: bool;
	var created_at: String;

	var line_items: Array;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.deleted = dict.get("deleted", false);
		self.title = dict["title"];
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

class LineItem:
	var id: String;
	var payment_id: String;
	var title: String;
	var amount_cents: int;

	func _init(dict: Dictionary):
		self.id = dict["id"];
		self.payment_id = dict["payment_id"];
		self.title = dict["title"];
		self.amount_cents = dict["amount_cents"];
