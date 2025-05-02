@tool
extends PanelContainer

@export var steps: Array[String] = [];
var step_active: Array[bool] = [];
var step_color: Array[Color] = [];
@export_tool_button("Force Update") var force_update = func() -> void: update_items();

func _enter_tree() -> void:
	update_items();

func set_active(index: int, active: bool):
	step_active[index] = active;
	update_items();

func add_item(text: String, active: bool = false) -> int:
	steps.push_back(text);
	step_active.push_back(active);
	step_color.push_back(Color(0.5, 0.5, 0.5));
	update_items();

	return steps.size() - 1;

func add_items(items: Array):
	for item in items:
		steps.push_back(item);
		step_active.push_back(false);
		step_color.push_back(Color(0.5, 0.5, 0.5));
	update_items();

func remove_item(index: int):
	steps.remove_at(index);
	update_items();

func clear_items():
	steps.clear();
	update_items();

func update_items():
	var list_parent = get_list_parent();
	step_active.resize(steps.size());
	step_color.resize(steps.size());

	for child in list_parent.get_children():
		child.queue_free();

	for i in steps.size():
		var label = _create_label(steps[i]);
		var final_col = Color(1, 1, 1) if step_active[i] else Color(0.5, 0.5, 0.5);
		if step_color[i] != final_col:
			label.create_tween().tween_property(label, "modulate", final_col, 0.25).finished.connect(func():
				step_color[i] = final_col;
			);
		else:
			label.modulate = final_col;
			step_color[i] = final_col;
		list_parent.add_child(label);

		if i < steps.size() - 1:
			var v_split = VSeparator.new();
			list_parent.add_child(v_split);

func get_list_parent():
	return $MarginContainer/HBoxContainer;

func _create_label(text: String):
	var label = Label.new();
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
	var label_settings = LabelSettings.new();
	label_settings.font_size = 16;
	label.label_settings = label_settings;
	label.text = text;
	label.name = text;
	return label;
