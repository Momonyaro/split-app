extends PanelContainer

@onready var line_title_label: Label = $VBoxContainer/HBoxContainer/VBoxContainer/FieldTitle;
@onready var line_title_edit: LineEdit = $VBoxContainer/HBoxContainer/VBoxContainer/LineEdit;
@onready var line_amount_label: Label = $VBoxContainer/HBoxContainer/VBoxContainer2/FieldTitle;
@onready var line_amount_edit: LineEdit = $VBoxContainer/HBoxContainer/VBoxContainer2/LineEdit;

@onready var line_submit_button: Button = $VBoxContainer/Button;

var on_submit_callback: Callable;

func _ready():
	line_submit_button.pressed.connect(_on_submit_pressed);
	pass

func _process(_delta: float):
	line_title_label.text = str("Name (", line_title_edit.text.length(), "/", line_title_edit.max_length, ")");

func setup(currency: String, result_callback: Callable):
	line_amount_label.text = str("Cost (", currency, ")");
	on_submit_callback = result_callback;

func _on_submit_pressed():
	var amount_is_valid = line_amount_edit.text.is_valid_float();
	var parsed_amount = line_amount_edit.text.to_float() if amount_is_valid else -0.0;

	var line_item: SQLPaymentUtils.LineItem = SQLPaymentUtils.LineItem.new({
		"id": IDUtils.create_id('PAYLI'),
		"title": line_title_edit.text,
		"amount_cents": roundi(parsed_amount * 100), # Round up to nearest cent to avoid floating point shenanigans.
	});

	line_title_edit.self_modulate = Color(1, 1, 1);
	line_amount_edit.self_modulate = Color(1, 1, 1);

	# Validate the object
	var is_valid = true;
	if line_item.title.length() == 0:
		line_title_edit.self_modulate = Color(1, 0, 0);
		is_valid = false;
	if not amount_is_valid:
		line_amount_edit.self_modulate = Color(1, 0, 0);
		is_valid = false;

	if not is_valid:
		return;

	line_amount_edit.text = "";
	line_title_edit.text = "";

	on_submit_callback.call(line_item);
