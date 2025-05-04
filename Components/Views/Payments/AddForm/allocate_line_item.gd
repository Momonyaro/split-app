extends PanelContainer

var participant_prefab = preload("res://Components/Views/Payments/AddForm/list_item_participant_object.tscn");
var prompt = preload("res://Components/Prompt/form_participant_prompt.tscn");
var hold_time = 0.3;
var _hold_timer = 0.0;
var holding = false;
var form_data: Dictionary;
var line_item: SQLPaymentUtils.LineItem;

var click_action: Callable;
var hold_action: Callable;

func _ready() -> void:
	_hold_timer = hold_time;

func _process(delta: float) -> void:
	if holding:
		_hold_timer -= delta;

func populate(_line_item: SQLPaymentUtils.LineItem, _form_data: Dictionary, callback: Callable):
	form_data = _form_data;
	line_item = _line_item;
	var list_parent = $VBoxContainer/ScrollContainer/HBoxContainer;
	var button = $Button;
	$VBoxContainer/HBoxContainer2/LineTitle.text = line_item.title;
	$VBoxContainer/HBoxContainer2/LineTotal.text = str(line_item.amount_cents / 100.0, ' ', form_data.currency);

	click_action = callback;
	hold_action = on_hold;

	button.button_down.connect(on_start_press)
	button.button_up.connect(on_end_press)

	for child in list_parent.get_children():
		child.queue_free()

	if line_item.participants.size() == 0:
		list_parent.get_parent().hide();
	else:
		list_parent.get_parent().show();

	for participant in line_item.participants:
		var contact = form_data.participants.filter(func(p):
			return participant.participant_id == p.id;
		)[0];
		var instance = participant_prefab.instantiate();
		instance.populate(participant, SQL.contact_utils.get_contact_by_id(contact.contact_id), form_data.currency, participant.participant_id == form_data.current_participant);
		list_parent.add_child(instance);

func _get_max_allotment() -> float:
	var line_total = line_item.amount_cents;
	var alloted = 0.0;
	for participant in line_item.participants:
		if participant.participant_id == form_data.current_participant:
			continue;
		if participant.has_fixed_amount():
			alloted += participant.fixed_amount_cents;
		elif participant.has_fixed_percentage():
			alloted += line_total * (participant.fixed_amount_percentage / 100.0);

	return line_total - alloted;

func on_hold():
	var hold_prompt = prompt.instantiate();
	hold_prompt.set_amount_callback(func(amount, percentage):
		line_item.participants = line_item.participants.filter(func(p):
			return p.participant_id != form_data.current_participant;
		);

		var new_line_part = SQLPaymentUtils.LineItemParticipant.new({
			"id": IDUtils.create_id('LIITP'),
			"line_item_id": line_item.id,
			"participant_id": form_data.current_participant,
			"fixed_amount_cents": amount,
			"fixed_amount_percentage": percentage
		});

		line_item.participants.push_back(new_line_part);
		# This hurts...
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().populate();
	);
	var max_allotment = _get_max_allotment();
	hold_prompt.set_total_max(max_allotment / 100.0);
	hold_prompt.set_total(line_item.amount_cents / 100.0);
	hold_prompt.set_line_item(line_item);
	hold_prompt.set_currency(form_data.currency);
	hold_prompt.set_participant(form_data.current_participant);
	get_tree().root.add_child(hold_prompt);

func on_start_press():
	holding = true;
	_hold_timer = hold_time;

func on_end_press():
	holding = false;
	if form_data.current_participant == "":
		return;

	if _hold_timer <= 0:
		hold_action.call();
	else:
		click_action.call();
