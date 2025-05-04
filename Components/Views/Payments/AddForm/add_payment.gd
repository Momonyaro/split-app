extends Panel

const STEP_OVERVIEW = 0;
const STEP_POPULATE = 1;
const STEP_ASSIGN = 2;
const STEP_CONFIRM = 3;

var popover_parent;
var contacts = [];

@onready var step_viewer = $VBoxContainer/StepViewer;

@onready var title_field: TextField = $VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/TextField;
@onready var id_label: Label = $VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/IDLabel;
@onready var currency_field: OptionButton = $VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/PanelContainer/VBoxContainer/OptionButton;
@onready var participant_menu: MenuButton = $VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/MenuButton;
var index_to_contact_id = {};
@onready var participant_added_parent = $VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/AddedParticipants;
@onready var participant_added: VBoxContainer = $VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/AddedParticipants/ScrollContainer/ParticipantList;

@onready var line_item_adder: PanelContainer = $VBoxContainer/STEP_CONTAINER/STEP_POPULATE/LineItemAdder;
@onready var added_items_header: Label = $VBoxContainer/STEP_CONTAINER/STEP_POPULATE/AddedItemsHeader;
@onready var line_item_list: VBoxContainer = $VBoxContainer/STEP_CONTAINER/STEP_POPULATE/ScrollContainer/VBoxContainer;
var line_item_prefab = preload("res://Components/Views/Payments/AddForm/line_item_prefab.tscn");

@onready var participant_selector = $VBoxContainer/STEP_CONTAINER/STEP_ASSIGN/ParticipantSelector;
@onready var allocate_list_parent = $VBoxContainer/STEP_CONTAINER/STEP_ASSIGN/Scroll/PanelContainer/VBoxContainer;
var allocate_item_prefab = preload("res://Components/Views/Payments/AddForm/allocate_line_item.tscn");

@onready var total_label: Label = $VBoxContainer/STEP_CONTAINER/STEP_CONFIRM/MarginContainer/VBoxContainer/Label2;
@onready var remainder_label: Label = $VBoxContainer/STEP_CONTAINER/STEP_CONFIRM/PanelContainer/VBoxContainer/HBoxContainer5/RemainderValue;
@onready var summary_part_list_parent: VBoxContainer = $VBoxContainer/STEP_CONTAINER/STEP_CONFIRM/PanelContainer/VBoxContainer/VBoxContainer;
var summary_part_list_item_prefab = preload("res://Components/Views/Payments/AddForm/summary_part_list_item.tscn");

@onready var cancel_button: Button = $MarginContainer/Buttons/Cancel;
@onready var submit_button: Button = $MarginContainer/Buttons/Submit;

var form_data = {
	"id": IDUtils.create_id('PAYMT'),
	"title": "New Payment",
	"currency": "SEK",
	"participants": [],
	"line_items": [],
	"current_step": STEP_OVERVIEW,
	"current_participant": ""
};

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed);
	submit_button.pressed.connect(_on_submit_pressed);
	title_field.value_changed.connect(_on_title_changed);
	currency_field.item_selected.connect(_on_currency_changed);
	participant_menu.get_popup().id_pressed.connect(_on_participant_selected);

	for child in $VBoxContainer/STEP_CONTAINER.get_children():
		child.hide();

	var default_currency = PersistentData.try_get_persistent(PersistentData.SETTING_DEFAULT_CURRENCY);

	for i in currency_field.item_count:
		var item_text = currency_field.get_item_text(i);
		if item_text == default_currency:
			currency_field.select(i);
			break;

	form_data["currency"] = currency_field.get_item_text(currency_field.selected);

	step_viewer.clear_items();
	step_viewer.add_item("Overview");
	step_viewer.add_item("Populate");
	step_viewer.add_item("Assign");
	step_viewer.add_item("Confirm");

	change_step(STEP_OVERVIEW);

	title_field.overwrite_value(form_data["title"]);
	id_label.text = str('ID -> ', form_data["id"]);
	populate();

func _process(_delta: float) -> void:
	participant_menu.get_popup().position.y = floori(participant_menu.global_position.y + participant_menu.size.y + 8);

func change_step(step: int) -> void:
	step = clampi(step, 0, STEP_CONFIRM);

	if step == form_data.current_step && step == STEP_CONFIRM:
		# Send it all to the SQL db.
		SQL.payment_utils.add_payment(form_data);
		populate();
		await popover_parent._t_close_menu();

		pass;

	match form_data.current_step:
		STEP_OVERVIEW:
			_tween_out_step($VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW);
			pass;
		STEP_POPULATE:
			_tween_out_step($VBoxContainer/STEP_CONTAINER/STEP_POPULATE);
			pass;
		STEP_ASSIGN:
			_tween_out_step($VBoxContainer/STEP_CONTAINER/STEP_ASSIGN);
			pass;
		STEP_CONFIRM:
			_tween_out_step($VBoxContainer/STEP_CONTAINER/STEP_CONFIRM);
			pass;

	cancel_button.text = "Back";
	submit_button.text = "Next";
	step_viewer.set_active(form_data.current_step, false);
	form_data.current_step = step;

	match step:
		STEP_OVERVIEW:
			_tween_in_step($VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW);
			step_viewer.set_active(step, true);
			cancel_button.text = "Cancel";
			pass;
		STEP_POPULATE:
			_tween_in_step($VBoxContainer/STEP_CONTAINER/STEP_POPULATE);
			step_viewer.set_active(step, true);
			pass;
		STEP_ASSIGN:
			_tween_in_step($VBoxContainer/STEP_CONTAINER/STEP_ASSIGN);
			step_viewer.set_active(step, true);
			pass;
		STEP_CONFIRM:
			_tween_in_step($VBoxContainer/STEP_CONTAINER/STEP_CONFIRM);
			step_viewer.set_active(step, true);
			submit_button.text = "Submit";
			pass;

func populate():
	contacts = SQL.contact_utils.get_contacts();

	populate_participants();
	populate_line_items();
	populate_assignments();
	populate_summary();
	pass;

func populate_participants():
	var current_participants = form_data["participants"];
	var popup = participant_menu.get_popup();
	popup.clear();

	participant_menu.disabled = false;
	if contacts.size() == 0:
		participant_menu.disabled = true;

	var no_available_participants = true;
	index_to_contact_id.clear();
	for i in contacts.size():
		var contact = contacts[i];
		var reserved = current_participants.filter(func (p): return p["contact_id"] == contact["id"]).size() > 0;
		if !reserved:
			no_available_participants = false;

		var has_avatar = contact.img_avatar != null;
		index_to_contact_id[i] = contact.id;

		if has_avatar:
			popup.add_icon_item(ImageTexture.create_from_image(contact.get_avatar()), contact.get_name(), i);
		else:
			popup.add_item(contact.get_name(), i);

		popup.set_item_disabled(i, reserved);
		popup.set_item_as_checkable(i, reserved);
		popup.set_item_checked(i, reserved);

	if no_available_participants:
		participant_menu.disabled = true;

	for child in participant_added.get_children():
		child.queue_free();

	if form_data.participants.size() == 0:
		var item = _create_participant_list_item("Empty.", false, func(): pass);
		participant_added.add_child(item);

	for i in form_data.participants.size():
		var participant = form_data.participants[i];

		var callback = func():
			form_data.participants.remove_at(i);
			populate();

		var contact = contacts.filter(func(c):
			return c.id == participant.contact_id;
		).front();

		var item = _create_participant_list_item(contact.get_name(), form_data["line_items"].size() == 0, callback);
		participant_added.add_child(item);
	pass;

func populate_line_items():
	line_item_adder.setup(form_data.id, form_data.currency, _on_line_item_added);
	added_items_header.text = str("Added Items (", form_data["line_items"].size(), ")");

	for child in line_item_list.get_children():
		child.queue_free();

	for i in form_data["line_items"].size():
		var line_item = form_data["line_items"][i];

		var callback = func():
			form_data["line_items"].remove_at(i);
			populate();

		var instance = line_item_prefab.instantiate();
		instance.get_child(0).get_child(0).text = line_item.title;
		instance.get_child(0).get_child(1).text = str(line_item.amount_cents / 100.0, ' ', form_data.currency);
		instance.get_child(0).get_child(2).pressed.connect(callback);

		line_item_list.add_child(instance);
	pass;

func populate_assignments():
	participant_selector.populate(form_data.participants, form_data.current_participant, _on_assign_participant_selected);

	for child in allocate_list_parent.get_children():
		child.queue_free();

	for i in form_data["line_items"].size():
		var line_item = form_data["line_items"][i];

		var callback = func():
			if form_data.current_participant == "":
				return;

			var filtered = line_item.participants.filter(func(participant):
				return participant.participant_id != form_data.current_participant;
			);

			if filtered.size() != line_item.participants.size():
				line_item.participants = filtered;
				populate();
				return;

			var line_participant = SQLPaymentUtils.LineItemParticipant.new({
				"id": IDUtils.create_id('LIITP'),
				"line_item_id": line_item.id,
				"participant_id": form_data.current_participant,
				"fixed_amount_cents": null,
				"fixed_amount_percentage": null
			});
			line_item.participants.push_back(line_participant);
			form_data["line_items"][i] = line_item;
			populate();

		var instance = allocate_item_prefab.instantiate();
		instance.populate(line_item, form_data, callback);
		allocate_list_parent.add_child(instance);

func populate_summary():
	var total = 0;
	var person_total = {};
	var remainder = 0;

	for participant in form_data.participants:
		person_total[participant.id] = 0;

	for line_item in form_data["line_items"]:
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

	for participant in form_data.participants:
		var contact = contacts.filter(func(c):
			return c.id == participant.contact_id;
		)[0];

		var instance = summary_part_list_item_prefab.instantiate();
		instance.populate(contact.get_name(), person_total[participant.id], form_data.currency);
		summary_part_list_parent.add_child(instance);
		pass;

	total_label.text = str("%0.2f" % (total / 100.0), ' ', form_data.currency);
	remainder_label.text = str("%0.2f" % (remainder / 100.0), ' ', form_data.currency);

func _create_participant_list_item(title: String, editable: bool, callback: Callable) -> Control:
	var item = HBoxContainer.new();
	var label = Label.new();
	label.text = title;
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	if title == "Empty.":
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5));
	item.add_child(label);

	var button = Button.new();
	button.flat = true;
	button.icon = ResourceLoader.load("res://Media/Icons/bomb-svgrepo-com.svg");
	button.add_theme_constant_override("icon_max_width", 24);
	button.pressed.connect(callback);
	button.disabled = !editable;
	if title != "Empty.":
		item.add_child(button);

	return item;

func _validate_step() -> bool:
	$VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/ErrorLabel.hide();
	$VBoxContainer/STEP_CONTAINER/STEP_POPULATE/ErrorText.hide();

	var valid = true;
	if form_data.current_step == STEP_OVERVIEW:
		if form_data.title.length() == 0:
			title_field.error_message = "Title cannot be empty";
			valid = false;
		if form_data.participants.size() == 0:
			$VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/ErrorLabel.show();
			$VBoxContainer/STEP_CONTAINER/STEP_OVERVIEW/ErrorLabel.text = "Participants cannot be empty";
			valid = false;
	elif form_data.current_step == STEP_POPULATE:
		if form_data.line_items.size() == 0:
			$VBoxContainer/STEP_CONTAINER/STEP_POPULATE/ErrorText.show();
			$VBoxContainer/STEP_CONTAINER/STEP_POPULATE/ErrorText.text = "Line items cannot be empty";
			valid = false;

	return valid;


func _on_title_changed(new_title: String):
	form_data["title"] = new_title;
	title_field.error_message = "Title cannot be empty" if new_title.length() == 0 else "";

func _on_currency_changed(idx_selected: int):
	var new_currency = currency_field.get_item_text(idx_selected);
	form_data["currency"] = new_currency;
	populate();

func _on_participant_selected(idx: int):
	var contact_id = index_to_contact_id[idx];
	var new_id = IDUtils.create_id('PPART');

	while new_id in form_data["participants"].map(func(p): return p.id):
		new_id = IDUtils.create_id('PPART');

	var participant = SQLPaymentUtils.PaymentParticipant.new({
		"id": new_id,
		"payment_id": form_data["id"],
		"contact_id": contact_id
	});
	form_data["participants"].push_back(participant);
	populate();

func _on_assign_participant_selected(id: String):
	if form_data.current_participant == id:
		form_data.current_participant = "";
	else:
		form_data.current_participant = id;
	populate();

func _on_line_item_added(item: SQLPaymentUtils.LineItem):
	form_data["line_items"].push_back(item);
	populate();

func _on_submit_pressed():
	if _validate_step():
		change_step(form_data.current_step + 1);

func _on_cancel_pressed():
	if form_data.current_step > STEP_OVERVIEW:
		change_step(form_data.current_step - 1);
		return;
	await popover_parent._t_close_menu();

func _tween_in_step(node: Control):
	node.show();
	node.modulate = Color(1, 1, 1, 0);
	node.create_tween().tween_property(node, "modulate", Color(1, 1, 1, 1), 0.1);

func _tween_out_step(node: Control):
	node.create_tween().tween_property(node, "modulate", Color(1, 1, 1, 0), 0.1);
	node.hide();
