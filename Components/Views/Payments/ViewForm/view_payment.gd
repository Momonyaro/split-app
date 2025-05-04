extends Panel

@onready var created_at_label: Label = $LIST/Label;
@onready var total_label: Label = $LIST/MarginContainer/VBoxContainer/Label2;
@onready var remainder_label: Label = $LIST/PanelContainer/VBoxContainer/HBoxContainer5/RemainderValue;
@onready var summary_part_list_parent: VBoxContainer = $LIST/PanelContainer/VBoxContainer/VBoxContainer;
@onready var delete_button: Button = $LIST/Buttons/Delete;
var summary_part_list_item_prefab = preload("res://Components/Views/Payments/AddForm/summary_part_list_item.tscn");

var popover_parent: PopoverMenu;
var prompt = preload("res://Components/Prompt/delete_prompt.tscn");
var payment: SQLPaymentUtils.Payment;

func _ready() -> void:
	var payment_id = popover_parent.subsection_keys[0];
	payment = SQL.payment_utils.get_payment(payment_id);

	if payment == null:
		return;

	var date = payment.get_created_at();
	created_at_label.text = str("Created -> ", date.year, "-", "%02d" % date.month, "-", "%02d" % date.day, " ", "%02d" % date.hour, ":", "%02d" % date.minute, ":", "%02d" % date.second);

	delete_button.pressed.connect(func():
		var delete_prompt = prompt.instantiate();
		get_tree().root.add_child(delete_prompt);
		delete_prompt.set_explode_action(_on_explosion);
		delete_prompt.set_fuse_length(1.0);
	);

	populate();

func populate():
	var total = 0;
	var person_total = {};
	var remainder = 0;

	for participant in payment.participants:
		person_total[participant.id] = 0;

	for line_item in payment.line_items:
		var line_total = line_item.amount_cents;
		total += line_total;

		var fixed_parts = line_item.participants.filter(func(p): return p.has_fixed_amount_or_percentage());
		var floating_parts = line_item.participants.filter(func(p): return !p.has_fixed_amount_or_percentage());

		for fixed in fixed_parts:
			if fixed.has_fixed_amount():
				person_total[fixed.participant_id] += fixed.fixed_amount_cents;
				line_total -= fixed.fixed_amount_cents;
			else:
				person_total[fixed.participant_id] += line_total * fixed.fixed_amount_percentage / 100.0;
				line_total -= person_total[fixed.participant_id];

		var floating_div = (line_total / floating_parts.size()) if floating_parts.size() > 0 else 0;
		var floating_amount = floating_div;
		for floating in floating_parts:
			person_total[floating.participant_id] += floating_amount;
			line_total -= floating_amount;

		remainder += line_total; # Add the remaining amount to the remainder variable

	for child in summary_part_list_parent.get_children():
		child.queue_free();

	for participant in payment.participants:
		var contact = SQL.contact_utils.get_contact_by_id(participant.contact_id);

		var instance = summary_part_list_item_prefab.instantiate();
		instance.populate(contact.get_name(), person_total[participant.id], payment.currency);
		summary_part_list_parent.add_child(instance);
		pass;

	total_label.text = str(total / 100.0, ' ', payment.currency);
	remainder_label.text = str(remainder / 100.0, ' ', payment.currency);

func _on_explosion():
	SQL.payment_utils.delete_payment(payment.id);
	popover_parent._t_close_menu();
