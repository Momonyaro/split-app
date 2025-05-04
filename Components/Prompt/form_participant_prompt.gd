extends Control

@onready var dimmed_fill = $ColorRect;
@onready var prompt_panel = $PanelContainer;
@onready var outside_warning = $PanelContainer/Control/Instructions;

var current_amount = 0.0;
var submitting_percentile = false;
var total = 0.0;
var total_max = 0.0;
var currency = "";
var line_item = null;
var participant_id = "";
var exiting = false;
var amount_callback = null;

var max_label;
var percent_label;
var percent_slider: HSlider;
var amount_label;
var amount_line_edit: LineEdit;

func _ready():
	max_label = $PanelContainer/VBoxContainer/HBoxContainer/FieldTitle2;
	percent_label = $PanelContainer/VBoxContainer/VBoxContainer2/FieldTitle;
	percent_slider = $PanelContainer/VBoxContainer/VBoxContainer2/HSlider;
	amount_line_edit = $PanelContainer/VBoxContainer/VBoxContainer/LineEdit;
	amount_label = $PanelContainer/VBoxContainer/VBoxContainer/FieldTitle;

	prompt_panel.pivot_offset = prompt_panel.size * 0.5;
	$PanelContainer/VBoxContainer/Button.pressed.connect(on_submit);
	max_label.text = str(total_max, ' ', currency);
	percent_label.text = str("Percentage (", roundi(current_amount / total_max * 100), "%)");
	percent_slider.set_value_no_signal(current_amount / total_max * 100 if total_max > 0 else 0.0);
	amount_label.text = str("Amount (", currency, ")");

	percent_slider.value_changed.connect(on_slider_changed);
	amount_line_edit.text_changed.connect(on_amount_changed);

	_tween_in();

func on_slider_changed(value: float):
	current_amount = value / 100.0 * total_max;
	amount_line_edit.text = str("%.2f" % current_amount);
	percent_label.text = str("Percentage (", roundi(current_amount / total_max * 100) if total_max > 0 else 0, "%)");
	submitting_percentile = true;


func on_amount_changed(text: String):
	if !text.is_valid_float():
		amount_line_edit.self_modulate = Color.RED;
		return;

	if text.to_float() > total_max:
		amount_line_edit.self_modulate = Color.RED;
		return;

	amount_line_edit.self_modulate = Color.WHITE;
	current_amount = float(text);
	percent_slider.set_value_no_signal(roundi(current_amount / total_max * 100) if total_max > 0 else 0);
	percent_label.text = str("Percentage (", roundi(current_amount / total_max * 100) if total_max > 0 else 0, "%)");
	submitting_percentile = false;


func on_submit():
	var amount_cents = null;
	var amount_percentage = null;

	if submitting_percentile:
		amount_percentage = roundi(current_amount / total * 100) if total > 0 else 0;
	else:
		amount_cents = current_amount * 100;

	amount_callback.call(amount_cents, amount_percentage);
	_tween_out();

func set_total_max(_max: float):
	total_max = _max;

func set_total(_total: float):
	total = _total;

func set_currency(_currency: String):
	currency = _currency;

func set_line_item(_line_item: SQLPaymentUtils.LineItem):
	line_item = _line_item;

func set_participant(id: String):
	participant_id = id;

func set_amount_callback(callback: Callable):
	amount_callback = callback;

func _tween_in():
	prompt_panel.scale = Vector2.ZERO;
	prompt_panel.modulate.a = 0;
	outside_warning.self_modulate.a = 0;
	dimmed_fill.self_modulate.a = 0;

	prompt_panel.create_tween().tween_property(prompt_panel, "scale", Vector2.ONE, 0.1);
	prompt_panel.create_tween().tween_property(prompt_panel, "modulate", Color(1, 1, 1, 1), 0.2);
	dimmed_fill.create_tween().tween_property(dimmed_fill, "self_modulate", Color(1, 1, 1, 1), 0.2);

	await get_tree().create_timer(0.5).timeout;
	outside_warning.create_tween().tween_property(outside_warning, "self_modulate", Color(1, 1, 1, 1), 1);

func _tween_out():
	prompt_panel.scale = Vector2.ONE;
	prompt_panel.modulate.a = 1;
	outside_warning.self_modulate.a = 1;
	dimmed_fill.self_modulate.a = 1;

	prompt_panel.create_tween().tween_property(prompt_panel, "scale", Vector2.ZERO, 0.1);
	prompt_panel.create_tween().tween_property(prompt_panel, "modulate", Color(1, 1, 1, 0), 0.1);
	dimmed_fill.create_tween().tween_property(dimmed_fill, "self_modulate", Color(1, 1, 1, 0), 0.2);
	outside_warning.create_tween().tween_property(outside_warning, "self_modulate", Color(1, 1, 1, 0), .2);

	await get_tree().create_timer(0.2).timeout;
	queue_free();


func _on_background_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and not exiting:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			exiting = true;
			_tween_out();
	pass # Replace with function body.
